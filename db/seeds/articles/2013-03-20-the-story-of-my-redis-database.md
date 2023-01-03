---
title: "From 1.5 GB to 50 MB: Debugging Memory Usage in Redis"
date: 2013-03-20 11:42
updated: 2022-12-29 12:57
---

Back when I was still working on [goodbre.ws](https://github.com/davidcelis/goodbre.ws) (well... rewriting, really), there was one big issue I was dealing with. Really big. Big enough to have taken down the entire site semi-permanently without me having access to more expensive servers. Long story short, my Redis database grew out of control and ballooned to 1.5 GB. The day before publising this for the first time, I reduced that memory usage to a cool 50 MB.

<!--more-->

In 2012, goodbre.ws was featured in [The Huffington Post](https://www.huffpost.com/entry/goodbrews-beer-recommendations-exploration-website_n_1930567) and [Lifehacker](https://lifehacker.com/goodbrews-keeps-track-of-the-beer-you-like-suggests-br-5947790); with those features came a small horde of new users, and I quickly found myself with 7000 new accounts. This was quite a change from humble beginnings with only a couple hundred friends, classmates and colleagues. Unfortunately, with all of these new people came a few problems. First, my background jobs to refresh recommendations slowed waaay down. I eventually discovered an I/O bottleneck in the background worker that was hitting both PostgreSQL and Redis more than it reasonably should have been. However, as more and more people were getting their recommendations, I saw my server’s RAM usage get worse and worse. It wasn’t long before the amount of RAM that Redis was trying to use had exceeded the amount of RAM on my server (1 GB). I couldn’t reasonably afford larger servers, especially at this rate of growth, and I was forced to take goobre.ws down.

I started doing a lot of thinking about my Redis usage and what could possibly be causing it to use so much memory. The first thing I considered was the length of my keys. Typical redis keys in my instance looked something like `recommendable:users:1234:liked_beers`. Okay. Multiply that by five for each user (for dislikes, bookmarks, hidden beers, etc.) and there’s a lot of repetition in the key names. They’re also quite long. Maybe Redis was eating memory by storing tens of thousands of really long key names in RAM? I decided to try shortening them to a more compact format: `u:1234:lb` for example.

With lots of hope, I renamed my keys and restarted Redis. Hopes dashed: that reduced memory usage by a meager 0.01 GB. That’s 10 MB which, for RAM, may be worth exploring again in the future. However, it obviously wasn’t my main problem.

Being a fairly junior engineer at the time, optimization wasn’t a rabbit hole I’d had to go down many times. I was hardly an expert, and I let my own self-consiousness and self-doubt get in the way of doing real testing. I immediately jumped to conclusions that maybe Redis wasn’t the tool I should be using. Maybe I should revert to storing ratings in PostgreSQL and accept what would certainly be a large performance hit during recommendation generation (Redis was perfect for this in my case because I was using [set math in a binary rating system](https://davidcel.is/articles/collaborative-filtering-with-likes-and-dislikes/)).

I toyed with the idea of finding some other data store. At the time, I couldn’t find a comparable key-value store that had the features I needed from Redis, namely both sets and sorted sets with the various operations I relied on for matching user similarities. The SET and ZSET data structures were just far too perfect for my usage. But what could I do? Redis obviously was becoming too expensive for me. I would have to find something else.

I thought about moving my ratings into a Neo4j graph database. It could make for an interesting way of generating recommendations, like a simple graph traversal out from a user to connected (similar) users to find beers that those users like frequently. That might even be faster, but I worried that the recommendations themselves wouldn’t be as good.

I also thought about moving the ratings back into PostgreSQL and initializing some sort of Ruby Set mapping when the Rails app booted up, but that would probably take just as much memory if not more. I’d just be moving RAM usage from Redis into Ruby.

Finally, the day before originally writing this post, I did what I should have done in the first place: I downloaded a [memory profiling tool built for Redis](https://github.com/sripathikrishnan/redis-rdb-tools) that would give me key-by-key memory usage stats. What I discovered was surprising, only because it outlined a problem I remember thinking about so long ago that I thought I had already addressed it.

My issue was how much data I was retaining in the sorted sets (ZSETs) I was creating. Each user got two ZSETs. One was used to store user similarities, pairing other users’ IDs with a calculated similarity value as the rank. The other ZSET stored recommendations, pairing beer IDs with the probability of the user liking that beer. In each ZSET, I was keeping those values for every other user and for every other beer. Multiply that by what became a database of 7000 users and 60000 beers and, well, you can guess what happened. Let’s just say that a lot of these sets were over 1 MB each.

I thought I was already truncating the ZSETs filled with similarity values by using a k-Nearest-Neighbor setting that I had introduced to [Recommendable](https://github.com/davidcelis/recommendable). That setting uses some specified number of similar users when generating recommendations as opposed to every user. Enabling that setting reduced the size of each similarity set from around 7000 values to 200 (100 similar users and 100 dissimilar users).

Additionally, I implemented a setting to specify how many recommendations should be kept at any one time for each user. I only ever show 10 recommendations, so maintaining those probabilities for every single beer was ridiculous. I reduced that to 100 as well so people can immediately get more recommendations if they rate their current ones. After truncating all of the sets to their specified lengths, I watched in awe as the memory Redis had been consuming dropped from 1.5 GB to 50 MB.

If you yourself are a [Recommendable](https://github.com/davidcelis/recommendable) user, definitely make use of the `nearest_neighbors`, `furthest_neighbors`, and `recommendations_to_store` settings!
