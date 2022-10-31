---
layout: post
title: "From 1.5 GB to 50 MB: The Story of my Redis Database"
date: 2013-03-20 11:42
categories: [programming, goodbrews, recommendable]
redirect_from:
  - /blog/2013/03/20/the-story-of-my-redis-database/

hackernews: http://news.ycombinator.com/item?id=5415219
---

It's been a while since I updated anybody on the current state of goodbre.ws. To make a long story short, I am in the midst of rewriting the site entirely. There are (or were) mainly two large problems for me. One big, niggling problem is that managing the database of beers on my own is impossible. My solution to this is to delegate that out to [BreweryDB](http://www.brewerydb.com/). They have so much more information on their beers than I do that it actually warrants a large rewrite of goodbre.ws. People have consistently asked for a more browsing-oriented experience as opposed to the current search-oriented experience. I'm going to deliver on that. The other big problem was how much memory my Redis instance was taking. Well, I have a small story about that. Yesterday, I reduced that memory usage from 1.5 GB to just 50 MB.

Last year, with the press on goodbre.ws came a small horde of new users. I found myself with a userbase of about 7000 people. Quite a change from humble beginnings of only a couple hundred friends, classmates and colleagues. However, with all of these new people came a few problems. First, my background jobs to refresh recommendations slowed waaay down. I eventually discovered an I/O bottleneck in the background worker that was hitting both Postgres and Redis more than it reasonably should have been. However, as more and more people were getting their recommendations, I saw my server's RAM usage quickly get worse and worse. It wasn't long before the amount of RAM that Redis was trying to use had exceeded the amount of RAM on my server (1 GB). I was forced to take goobre.ws down, and here we are.

I started doing a lot of thinking about my Redis usage. What could possibly be causing it to use that much memory? I considered the length of my keys. Typical redis keys looked something like `recommendable:users:1234:liked_beers`. Okay. Multiply that by five for each user (for dislikes, bookmarks, hidden beers, etc.) and there's a lot of repetition in the key names. They're also quite long. Maybe Redis was eating memory by storing tens of thousands of really long key names in RAM? I decided to try shortening them to a more reasonable format: `u:1234:lb` for example.

With lots of hope, I renamed my keys and restarted Redis. Hopes dashed: that reduced memory usage by a paltry 0.01 GB. That's 10 MB which, for RAM, may be worth exploring again in the future. However, it obviously wasn't my main problem.

Optimization is a rabbit hole I've not had to go down very often. I am hardly an expert. I let my own self-consiousness and self-doubt  get in the way of doing real testing. I immediately jumped to conclusions that, perhaps, Redis was not the tool I wanted to be using. Maybe I should revert to storing ratings in PostgreSQL and accept what would certainly be a large performance hit during recommendation generation.

I toyed with the idea of finding some other data store. I couldn't find a key- value store that, like Redis, had sets and sorted sets but, unlike redis, was not in-memory. I also didn't want to give up the in-memory bit. It's just so fast. The SET and ZSET data structures were also far too perfect for my usage. But what could I do? Redis obviously was becoming too expensive for me. I would have to find something else.

I thought about moving my ratings into a Neo4j graph database. It could make for an interesting way of generating recommendations: it could be a simple graph traversal out from a user to connected (similar) users to find beers that those users like frequently. That would probably even be faster. However, the recommendations themselves would not be as good.

I also thought about simply moving the ratings back into Postgres and initializing some sort of Ruby Set mapping when the Rails app booted up, but that would probably take just as much memory if not more. I'd only be moving RAM usage from Redis to Rails.

Finally, yesterday, I did what I should have done in the first place. I downloaded a [memory profiling tool](https://github.com/sripathikrishnan/redis-rdb-tools) built for Redis that would give me key-by-key memory usage stats. What I discovered was surprising, because it outlined a problem I remember thinking about a long time ago. So long ago, in fact, that I thought I had already addressed it.

My issue was how much data I was retaining in each sorted set (ZSET). Each user gets two ZSETs. One is used to store user similarities, and pairs other users' IDs with a calculated similarity value as the rank. The other ZSET stores recommendations, pairing beer IDs with the probability of them liking that beer. In each ZSET, I was keeping those values for every other user and for every other beer. Multiply that by what became a database of 7000 users and 60000 beers and, well, you can guess. Let's just say that a lot of these sets were over 1 MB each.

I thought I was already truncating the ZSETs filled with similarity values by using a k-Nearest-Neighbor setting that I had introduced to Recommendable. That setting uses some specified number of similar users when generating recommendations as opposed to every user. Enabling that setting reduced the size of each similarity set from around 7000 values to 200 (100 similar users and 100 dissimilar users).

Additionally, I implemented a setting to specify how many recommendations should be kept at any one time for each user. I only ever show 10 recommendations, so maintaining those probabilities for every single beer was ridiculous. I reduced that to 100 as well so people can immediately get more recommendations if they rate their current ones.

After truncating all of the sets to their specified lengths, I watched in awe as the memory Redis had been consuming dropped from 1.5 GB to 50 MB. I don't think I'll be having memory usage issues with Redis for a long time.

If you're a [Recommendable](https://github.com/davidcelis/recommendable) user, I highly suggest you make use of the `nearest_neighbors`, `furthest_neighbors`, and `recommendations_to_store` settings.
