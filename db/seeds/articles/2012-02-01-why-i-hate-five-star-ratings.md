---
layout: post
title: "Why I Hate Five-Star Ratings"
date: 2012-02-01 11:50
categories: [programming, recommendable]
redirect_from:
  - /blog/2012/02/01/why-i-hate-five-star-ratings/
---

A question I get often when discussing [goodbre.ws][1] and, more recently, [recommendable][0], is why I chose to implement a system based on Likes and Dislikes rather than the more standard five-star rating scale. Usually, I'm short and succinct: I think that star rating systems suck. Sometimes, I do go into a bit more detail: I think that star rating systems really suck. However, I'm starting to think that people may be asking this question and expecting some sort of "actual answer", so today I would like to go into just why I think that the five-star rating scale is terrible, and why I decided to use the binary system of likes and dislikes.

## The ★★★★★ scale

The star rating scale is arguably the most classic of all, so it's not surprising that a lot of websites use it. Big e-commerce sites like Amazon and eBay utilize the five-star scale, and Netflix also uses a five-star scale to power its review system and recommendations. There are, of course, variations. IMDB uses a ten-star scale, which may as well be a 5-star scale that allows half stars (such as reviews on BeerAdvocate). There are a lot of ways to handle the star-scale, but what I'd like to get at is that they all suck.

### Ambiguity and uncertainty of the scale

One of my big gripes about the five-star scale is ambiguity behind the ratings that you are allowed to give. What exactly distinguishes between three stars and four stars? What is enough to push your rating up to that next star? What is enough to pull it down? Because of a lack of clarity, star ratings can end up being very subjective. It is easy to end up with two people who give an item the same three-star rating but actually feel differently about it. Some websites attempt to handle this reasonably. Netflix, for instance, used to present some explanatory text for each star when hovering over them during a rating:

★☆☆☆☆ (Hated it)
★★☆☆☆ (Didn't like it)
★★★☆☆ (Liked it)
★★★★☆ (Really liked it)
★★★★★ (Loved it)

At the time of writing this post, Netflix no longer displays this text when submitting a rating. Instead, posting a rating to Netflix now closely resembles the act of doing so on Amazon: you are simply presented with five clickable stars and left alone with your fears and preconceptions. This is how it often is when submitting a star rating.

However, even the explanatory text itself can end up coming off as subjective. What does it mean to "really" like a movie? Why are the intervals between the options unequal (i.e. no "Really disliked it" option)? The explanatory text can help if done correctly, but it can also simply add to the subjectivity of submitted ratings.

### Unreliability of ratings

Because a star rating scale iteslf is so ambiguous and uncertain, so too are the ratings submitted to it. Many users will not use this scale as intended even with intent given in the form of explanatory text. Many users _will_ use the scale as intended, but that usage is always based on their subjective ability to understand the way the scale should be used.

Despite this, recommendation systems will accept these ratings as statistically accurate communications. Websites with huge samples of users and ratings may not seem to be negatively affected by the unreliable nature of these ratings. It is likely that that this unreliability becomes normalized as the data sample grows. Smaller websites and recommendation systems experiencing the [cold start][2], however, will suffer due to the subjective nature of its small rating sample.

### Binary voting is already happening

Despite being a scale with five possible ratings, people tend to vote in a binary fashion anyway. Back in 2009, YouTube [published some interesting data][3] concerning the ratings that videos had been receiving. As it turns out, a huge majority of videos would receive mostly five-star ratings. I think that YouTube's takeaway from this data was spot on:

> Seems like when it comes to ratings it's pretty much all or nothing. Great videos prompt action; anything less prompts indifference.

The second highest rating was, of course, one star. This is a great example of binary voting in the works. A lot of people give mostly five-star ratings for things they like. If they don't like that thing, they either give it one star or simply bounce and skip rating it entirely. I've also spoken to friends and acquaintances who admit to giving almost exclusively four-star ratings to things they like, and three-star ratings to things that are "just ok".

YouTube toyed with the idea of switching their rating system to a "favorites" system to "declare your love for a video", but ultimately settled on the thumbs up or down options we know and love today. There was some level of outcry from YouTube users expressing dismay at the change in rating scale, but there's been no evidence to support this group as anything more than a loud minority.

## The binary scale (and why it's better)

Binary rating scales are another popular system. As mentioned earlier, YouTube now operates on a thumbs up or down rating scale. Other websites that utilize a similar scale include reddit (upvotes and downvotes) and digg (digging or burying). Some social networking sites take this even a step further and remove the negative rating option entirely (e.g. Facebook only has likes and Google+ has only has the +1 button). I'd like to focus on the classic Like/Dislike pair. What makes this system better than a five-star system?

### Less ambiguous

The binary rating scale removes a large amount of ambiguity present in the star rating systems. Five (or more) subjective rating options are aggregated down into two options based on words that are easily understandable by native speakers of the language. It is much easier for a person to declare, "Hey, I like this thing" than it is to determine, "Well, I like this thing... But do I 'three stars' like it, or do I 'four stars' like it?"

### Less subjective

A large amount of subjectivity is also removed. Ratings given that are based directly on feelings are much more likely to match than ratings given based on numbers. This can simplify a lot of situations in which two people may have similar feelings about something but rated it different:

* Me: "I liked this thing and rated it four stars."

  Friend: "I liked this thing and rated it five stars."
* Me: "I liked this thing and rated it three stars."

  Friend: "I didn't like this thing, so I only gave it three stars."

Our feelings about something are clearly not conveyed well by star ratings, and they don't match. As I posited earlier, this can normalize given a large set of data, but this does not change that we have no way of knowing whether or not the underlying ratings are truly indicative of agreement. Given a binary scale, however, agreement is much more clear: "We both liked this thing" or "we both disliked this thing."

### People are already doing this!

Third, as stated earlier, _people are pretty much already rating in this way_. Why fight it?

### No middle ground

Of course, the Like/Dislike system is not without its own flaws. Most notably, unless implemented, there isn't an explicit neutral ground in a binary rating system aside from abstaining from a vote. It's an all-or-nothing situation in which you either like something or you don't. This may or may not be an issue for you as the implementor. Personally, when I'm ready to rate an item, I can always manage to categorize it into a like or dislike even if its very close. However, if I were to truly feel 100% neutral about something, I would likely ignore that thing and move on rather than rate it. If I have no feelings either way, why would I want it affecting my recommendations?

## tl;dr

Embrace the binary rating system. It's much less ambiguous and subjective than its stellar cousin, and it's much easier for the user to deal with in general. Feelings themselves are more easily comparable than numbers indirectly based on feelings and can lead to more accurate recommendations.

[0]: http://davidcelis.github.io/recommendable
[1]: http://goodbre.ws/
[2]: http://en.wikipedia.org/wiki/Cold_start
[3]: http://youtube-global.blogspot.com/2009/09/five-stars-dominate-ratings.html
