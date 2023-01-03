---
title: "Why I Hate Five-Star Ratings"
date: 2012-02-01 11:50
updated: 2022-12-29 9:23
---

When I was originally developing [goodbre.ws][1] (and, later, [recommendable][0]), the very first thing I had to decide was how users would rate items. Would I give them a standard five star system? Maybe something with more granularity, like allowing for half stars? Or perhaps the humble thumbs up or down? Truth be told, going with a binary thumbs up or down system of likes and dislikes was an easy choice. After all, I _hate_ the five-star rating system.

<!--more-->

## The ★★★★★ scale

At its core, any star rating scale is just a numeric rating scale with some number of options. The five-star scale is arguably the most classic of its kind (psychologically, five options "feels" like a nice, round number), so it’s not surprising that a lot of websites use it. Most big e-commerce sites like Amazon, eBay, or stores powered by Shopify allow you to rate products using five stars. IMDB uses a ten-star scale, which may as well be a 5-star scale that allows half stars. Untappd uses a five-star scale but with the granularity of quarter stars, which gives you 20 options. There are a lot of numeric systems, but they all have the same, core issues.

### Ambiguity and uncertainty of the scale

One of my big gripes about numeric scales like the five-star scale is the ambiguity behind the ratings that you are allowed to give. What exactly distinguishes between three stars and four stars? What’s enough to push your rating up to that next star? What’s enough to pull it down? Because of a lack of clarity, star ratings can end up being highly subjective. It’s easy to end up with two people who give an item the same three-star rating when they actually feel differently about that item. Some websites attempt to handle this reasonably; back when Netflix still used a five-star scale, they presented some explanatory text for each star when hovering over while rating a movie:

1. ★☆☆☆☆ (Hated it)
2. ★★☆☆☆ (Didn’t like it)
3. ★★★☆☆ (Liked it)
4. ★★★★☆ (Really liked it)
5. ★★★★★ (Loved it)

Eventually, Netflix stopped displaying this hover text, instead letting ambiguity creep back in. That being said, even the explanatory text itself can come off as subjective. What does it mean to "really" like a movie? Why are the intervals between the options unequal, with there being no "Really disliked it" option and with the typically neutral three-star text being very much _not_ neutral? Explanatory text can help if done correctly, but it can also add to the subjectivity of submitted ratings.

### Unreliability of ratings

Because a star rating scale iteslf is so ambiguous and uncertain, the ratings end up reflecting that ambiguity and uncertainty. Many users will not use this scale as intended even with intent given in the form of explanatory text. Some users _will_ use the scale as intended, but that usage is always based on their subjective ability to understand the way the scale should be used.

Despite this, recommendation systems will accept these ratings as statistically accurate communications. Websites with huge samples of users and ratings are less likely to be negatively affected by the unreliable nature of these ratings; as sample sets grow, that unreliability can become normalized. Smaller websites and recommendation systems experiencing the [cold start][2], however, will suffer due to the subjective nature of their small rating samples.

### Binary voting is already happening

Despite being given a scale with five possible ratings, most people tend to vote in a binary fashion anyway. Back in 2009, YouTube [published some interesting data][3] concerning the ratings that videos had been receiving. As it turns out, a huge majority of videos would receive mostly five-star ratings. I think that YouTube’s takeaway from this data was spot on:

> Seems like when it comes to ratings it’s pretty much all or nothing. Great videos prompt action; anything less prompts indifference.

The second highest rating was, of course, one star; this is a great example of binary voting in the works. A lot of people give mostly five-star ratings for things they like. If they don’t like a thing, they either give it one star or just bounce without rating the thing at all. I’ve also spoken to numerous friends and acquaintances who admit to giving almost exclusively four-star ratings to things they like, and three-star ratings to things that are "just ok". In fact, this is a wide-spread phenomenon on Tabelog, a popular website used in Japan to rate restaurants. So many reviews on Tabelog stick to the middle of the road that, on average, [most of its ratings are distributed between 3.1 and 3.5 stars](http://tabelog.com/help/score/).

YouTube toyed with the idea of switching their rating system to a "favorites" system to "declare your love for a video", but ultimately settled on likes and dislikes.

## The binary scale (and why it’s better)

Binary rating scales have gained a lot of popularity. As mentioned earlier, YouTube has now operated on a thumbs up or down rating scale for a long time. Netflix also eventually dropped their star-rating system in favor of likes and dislikes. Reddit and other social networking sites like it use upvotes and downvotes. But what makes a binary system better than a five-star system?

### Less ambiguity

The binary rating scale removes a large amount of ambiguity present in the star rating systems. Five or more subjective rating options are aggregated down into two options based on words that are easily understandable by native speakers of the language. It is much easier for a person to declare, "Hey, I like this thing" than it is to determine, "Well, I like this thing... But do I ‘three stars’ like it, or do I ‘four stars’ like it?"

### Less subjectivity

A large amount of subjectivity is also removed. Ratings given that are based directly on feelings are much more likely to match than ratings given based on numbers. This can simplify a lot of situations in which two people may have similar feelings about something but rated it different:

* Me: "I liked this thing and rated it four stars."<br/>
  Friend: "I liked this thing and rated it five stars."
* Me: "I liked this thing and rated it three stars."<br/>
  Friend: "I didn’t like this thing, so I only gave it three stars."

Our feelings about something are clearly not conveyed well by more granular ratings, and they also don’t match. As I posited earlier, this will normalize as data sets grow, but this does not change that we have no way of knowing whether or not the underlying ratings are truly indicative of agreement. Given a binary scale, however, agreement is much more clear: "We both liked this thing" or "we both disliked this thing."

### People are already doing this!

Remember, even within a five-star system or other numeric systems, _people are pretty much already rating in this way_. Why fight it?

### No middle ground

Of course, the likes and dislikes are not without their own flaws. Most notably, unless its explicitly added, there isn’t an obvious neutral ground in a binary rating system outside of abstenance. It’s often an all-or-nothing situation in which you either like something or you don’t. This may or may not be an issue for you as the implementor. Personally, when I’m ready to rate an item, I can almost always manage to categorize it into a like or dislike even if its very close. However, if I were to truly feel 100% neutral about something, I would likely ignore that thing and move on rather than rate it. If I have no feelings either way, why would I want it affecting my recommendations?

## tl;dr

Embrace the binary rating system. It’s much less ambiguous and subjective than its stellar cousin, and it’s much easier for the user to deal with in general. Feelings themselves are more easily comparable than numbers indirectly based on feelings and can lead to more accurate recommendations.

[0]: https://github.com/davidcelis/recommendable
[1]: https://github.com/davidcelis/goodbre.ws
[2]: https://en.wikipedia.org/wiki/Cold_start_(recommender_systems)
[3]: http://youtube-global.blogspot.com/2009/09/five-stars-dominate-ratings.html
