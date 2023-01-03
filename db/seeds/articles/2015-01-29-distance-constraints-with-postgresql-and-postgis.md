---
title: "Distance Constraints with PostgreSQL and PostGIS"
date: 2015-01-29 18:44
updated: 2022-12-29 14:31
---

So you’re a squirrel, and winter is coming. It’s time to start gathering nuts for... woah, wait! Come back! Remember last year? _Sigh_, of course you don’t... You squirrels have great spatial memory for their caches, but not the spots you’ve foraged in. Last year, you did a lot of searching for nuts in places you’d already cleaned out. What a waste of time! Don’t worry, though; I’m here to help! To increase your productivity, we’re going to keep a spatial database of all of your foraging spots.

<!--more-->

One of the most popular solutions for spatial databases is [PostGIS](http://postgis.net/). PostGIS is a [PostgreSQL](https://www.postgresql.org/) extension that adds support for spatial data types and queries. This should suit our needs perfectly! Let’s start by opening up your command line and installing both PostgreSQL and PostGIS, and then initializing a new database! If you’re on macOS, you can install both using [Homebrew](https://brew.sh/); if you’re on Ubuntu, you can use `apt-get`.

```sh
# Mac OS X
brew install postgresql postgis
createdb nutsy

# Ubuntu
sudo apt-get install postgresql-9.4-postgis-2.1
createdb nutsy
```

Alternatively, if you use Docker, there’s a community-maintained [PostGIS Docker Image](https://github.com/postgis/docker-postgis)!

Anyway, now we’ve got a PostgreSQL database named `nutsy`. Normally you’d want to use some sort of migration utility to help you manage your database schema, but let’s just jump into our PostgreSQL console to play around. Just type `psql -d nutsy` in your command line. You should see something like:

```
psql (14.6)
Type "help" for help.

nutsy=#
```

What we want to end up with is a table we can use to keep track of your past foraging spots. PostGIS gives us a few special data types to store things like points, lines, or polygons on a coordinate. The main two data types are geometries and geographies. Geometries are used to represent objects in a Euclidean coordinate system. Geographies, on the other hand, are used to represent objects in the round-earth coordinate system. While either geometries or geographies could make sense for the task at hand, our specific calculations will be made easier if we use geographies.

```sql
CREATE EXTENSION "postgis";

CREATE TABLE foraging_spots (
  id          SERIAL                 PRIMARY KEY,
  coordinates GEOGRAPHY(POINT, 4326) NOT NULL,
  nuts        INT
);
```

In the first line of this file, we’re enabling usage of the PostGIS extension in our database, allowing us to use its functions and types. Then we create a table named `foraging_spots` with an auto-incrementing ID, coordinates, and an optional number of nuts found in that spot. The coordinates takes advantage of the `GEOGRAPHY` type given to us by PostGIS. That type takes two parameters:

1. A type modifier. Valid choices here are `POINT`, `LINESTRING`, `POLYGON`, `MULTIPOINT`, `MULTILINESTRING`, and `MULTIPOLYGON`. We’re representing points on a coordinate system, so we passed in `POINT`.
2. A unique Spatial Reference Identifier (SRID). 4326 is the SRID for the geographic latitude/longitude coordinate system of the Earth and is a default for many PostGIS types, so we’ll keep that as our SRID as well.

Now that we have our geography column, we can start adding some locations that we’ve foraged in. I see you live in New York City’s Central Park. That wouldn’t be my first choice, but... Whatever makes you happy! Maybe you get a lot of free food from the tourists. Anyway, let’s add a few spots in the park that you’ve searched. Five should be enough:

```sql
--- A little island in Turtle Pond
INSERT INTO foraging_spots (nuts, coordinates) VALUES (4, ST_GeographyFromText('POINT(-73.968504 40.779741)'));

--- Around the Obelisk
INSERT INTO foraging_spots (nuts, coordinates) VALUES (9, ST_GeographyFromText('POINT(-73.965393 40.779640)'));

--- One of the softball fields in the Great Lawn
INSERT INTO foraging_spots (nuts, coordinates) VALUES (17, ST_GeographyFromText('POINT(-73.966256 40.780602)'));

--- In the Shakespeare Garden
INSERT INTO foraging_spots (nuts, coordinates) VALUES (12, ST_GeographyFromText('POINT(-73.969861 40.779859)'));

--- In "The Ramble", whatever that is!
INSERT INTO foraging_spots (nuts, coordinates) VALUES (7, ST_GeographyFromText('POINT(-73.969046 40.776146)'));
```

Okay! Now we have five foraging spots in our new table. This uses the `ST_GeographyFromText` function given to us by PostGIS. This takes a string representation of a `POINT` and uses it to construct a native Geography that can then be stored in our table. So this ends up taking the form of `ST_GeographyFromText('SRID=4326;POINT(longitude latitude)'))`. In our examples, we left out the SRID declaration because an SRID of 4326 is assumed; we don’t have to specify it.

Now, let’s say you go out on another run. You remember that you found a good number of nuts out in the Great Lawn, so you venture there again. It’s full of softball fields! You remember that you searched near one of them, but you don’t remember which. You want your database to be able to tell you if you start searching near the same field as last time. Your first thought is probably to put a uniqueness constraint[^1] on your coordinates field:

```sql
CREATE UNIQUE INDEX coordinates_gix ON foraging_spots (coordinates);
```

Now, let’s see what happens when we try to create a point with the same coordinates as last time:

```sql
--- That same softball field in the Great Lawn
INSERT INTO foraging_spots (coordinates) VALUES (ST_GeographyFromText('POINT(-73.966256 40.780602)'));
--- ERROR:  duplicate key value violates unique constraint "coordinates_gix"
--- DETAIL:  Key (coordinates)=(0101000020E61000009A982EC4EA63444015E46723D77D52C0) already exists.
```

Our index works! ... If you input the exact same coordinates. However, you are quite thorough in your searching. When you’ve added a point to your database, you know that you conducted a search that extends in a 50 meter radius around that point. Because geographic coordinates are so precise, it’s unlikely that you would try to search in the _exact_ same spot. But if you try to start a new search even a single meter away from the old one...

```sql
--- That same softball field in the Great Lawn, but shifted eeever so slightly...
INSERT INTO foraging_spots (coordinates) VALUES (ST_GeographyFromText('POINT(-73.966246 40.780612)'));
--- INSERT 0 1
```

Uh oh. That point is _very_ close to our original point in the Great Lawn... Definitely within 50 meters of it. So how do we prevent ourselves from this sort of overlap? Unfortunately, PostGIS doesn’t seem to give us any sort of index or constraint that lets us do this easily... However, PostGIS does give us a nice function we can try to utilize: `ST_DWithin()`.

`ST_DWithin()` takes two geographies and, in the case of our SRID, a number of meters. It will return `true` if the two geographies are within that number of meters of each other, and `false` if not. This isn’t usable from an index or uniqueness constraint, but we can use it in a different way. At a high level, we’re going to create a sort of check that raises an exception if a foraging spot is within 50 meters of an existing one. Then, we’re going to make PostgreSQL call that function every time a foraging spot has been added or modified.

```sql
CREATE FUNCTION check_distance() RETURNS trigger AS $check_distance$
  BEGIN
    IF (SELECT 1 FROM foraging_spots WHERE ST_DWithin(NEW.coordinates, foraging_spots.coordinates, 50)) THEN
      RAISE EXCEPTION 'You already search this spot! Go somewhere else!';
    END IF;

    RETURN NEW;
  END;
$check_distance$ LANGUAGE plpgsql;

CREATE TRIGGER check_distance
  BEFORE INSERT OR UPDATE ON foraging_spots
  FOR EACH ROW
  EXECUTE PROCEDURE check_distance();
```

Okay, there’s a lot going on here! First, we’ve just created a function named `check_distance()` that will compare a new foraging spot with all existing foraging spots. The new foraging spot is helpfully assigned to `NEW` because we’ll be using the function as a trigger (more on that in a bit). We execute a query as a conditional check:

`SELECT 1 FROM foraging_spots WHERE ST_DWithin(NEW.coordinates, foraging_spots.coordinates, 50)`. If the new foraging spot is found to be within 50 meters of any existing foraging spot, that statement returns `1`, passes the condition, and will raise an exception with a helpful message. If the two spots are sufficiently far apart, the condition fails and our function simply returns the new foraging spot.

Finally, we use the `CREATE TRIGGER` statement to tell PostgreSQL that we want this function called before any `INSERT` or `UPDATE` statement is called on the `foraging_spots` table. We want it to be called `FOR EACH ROW` as opposed to `FOR EACH STATEMENT`, since a single statement could insert multiple rows. For each row added in an `INSERT` statement or modified in an `UPDATE` statement, `check_distance()` will be called with `NEW` assigned with the new or updated values.

We should be good to go with this new distance check. Let’s remove that last foraging spot that we added in error, and try adding it again:

```sql
--- Delete our bad foraging spot (it should just be the last one)
DELETE FROM foraging_spots WHERE id IN (SELECT id FROM foraging_spots ORDER BY id DESC LIMIT 1)
--- DELETE 1

--- Now, try to add it again
INSERT INTO foraging_spots (coordinates) VALUES (ST_GeographyFromText('POINT(-73.966246 40.780612)'));
--- ERROR:  You already search this spot! Go somewhere else!
```

Great! Now when you add a location that you’re going to start foraging in, your database will tell you if it’s within 50 meters of a spot you already searched. If it is, you should probably go somewhere else! Happy hunting!

[^1]: It’s worth mentioning that, under normal circumstances, we would want to create a GiST (Generalized Search Tree) index. This is because PostGIS data types don’t play well with the typical B-Tree indices that PostgreSQL use by default. However, PostgreSQL doesn’t support unique GiST indices so we must stick with the default.
