---
layout: post
title: "Collaborative Filtering With Likes and Dislikes"
date: 2012-02-07 13:10
categories: [programming, ruby, rails, recommendable]
redirect_from:
  - /blog/2012/02/07/collaborative-filtering-with-likes-and-dislikes/
---

Ah, caught your attention, did I? Well, now that I have it, I'd like to sit down and have a chat. We need to talk, friend, and we _need_ to talk about collaborative filtering. It's a technique used in recommendation engines. Please repeat the following:

> This is collaborative filtering. There are many different kinds of collaborative filtering, but mine is memory-based. Memory-based collaborative filtering is my best friend.
>
> — Gunnery Seargeant Hartman, Full Metal Jacket

Okay, so I may be taking some creative liberty with this one. You shouldn't be best friends with any one form of collaborative filtering. They all deserve love and they all have their uses. I'm sure the gunnery seargeant would agree with me! However, I *would* like to focus on memory-based collaborative filtering today as the algorithms that fall into this category are used often in recommender systems. Additionally, I'm going to go ahead and shift us into the context of a binary rating system: likes and dislikes. Okay? Okay!

My good (but not best!) friend, memory-based collaborative filtering, uses submitted ratings to calculate a numeric similarity between users. Wait, what!? You mean that two people can be compared and that comparison can yield a number? You bet! We can *all* be reduced to numbers. It's a Brave New World, reader! These similarity values can then be used to predict how a user will feel about items they have not yet rated. The top predictions are given back to the user in the form of recommendations! It's like having your mind read. Except by a computer! And instead of reading your mind, it's doing math!

There are a good number of different algorithms used in memory-based collaborative filtering to calculate the similarity between users. A few of the more widely used algorithms or formulae include [Euclidean Distance][euclidean], [Pearson's Correlation][pearson], [Cosine-based vector similarity][cosine], and the [k-Nearest Neighbor algorithm][knn]. These are all well documented on the internets and multiple example implementations are available should you wish to know more. They're all great for the heavily-used five-star system, but that's so common! So boring! So passé I want to talk about something *else*. I want to talk about an algorithm I don't see used often but would work great for my other friends, Like and Dislike. I want to talk about the Jaccard similarity coefficient!

## Jean-Luc Jaccard?

No, no, no. I'm talking about Paul Jaccard, a botanist that performed research near the turn of the 20th century. Jaccard's research led him to develop the *coefficient de communauté*, or what is known in English as the Jaccard similarity coefficient (also called the Jaccard index). The Jaccard index is a simple calculation of similarity between sample sets. Where the aforementioned collaborative filtering algorithms can quickly become mathematically complex, the Jaccard index is rather simple! It can be described as the size of the intersection between two sample sets divided by the size of the union between the same sample sets. Look over there! It's math!

$$
J(u_1,u_2)=\frac{\left |u_1 \bigcap u_2\right |}{\left |u_1\bigcup u_2 \right |}
$$

I bet those mushy brain-gears of yours are already slimily grinding away at how intuitive this formula can be when used with likes and dislikes!

Let's say we're comparing two users u<sub>1</sub> and u<sub>2</sub>. How does one intersect two users? How does one union them? Well, we don't want to intersect or union the people themselves. This isn't Mary Shelly's Frankenstein! If we're using the Jaccard index for collaborative filtering, we want both of these operations to deal with the users' ratings. Let's say that the intersection is the set of only the items that the two users have rated in common. This would make the union the combined set of items that each user has rated independently of the other. But how does this work with the actual ratings? Let's modify the formula a bit to deal with the likes and dislikes themselves:

$$
J(u_1,u_2)=\frac{\left |L_{u1} \bigcap L_{u2}\right |+\left |D_{u1} \bigcap D_{u2}\right |}{\left |u_1\bigcup u_2 \right |}
$$

Now we're getting somewhere! What we have now is looking more collaborative and filtery for sure. We find the number of items that both u<sub>1</sub> and u<sub>2</sub> like, add it to the number of items that both u<sub>1</sub> and u<sub>2</sub> dislike, and then divide that by the total number of different items that u<sub>1</sub> and u<sub>2</sub> have rated.

## Hey, wait! I like \[INSERT THING HERE\] and he doesn't!

Well first of all, shame on him. \[INSERT THING HERE\] is gold. Solid gold! But also, you raise an excellent point, sir and/or madam! Disagreements should, at the very least, matter just as much as agreements. Let's tweak the formula a bit more, shall we?

$$
J(u_1,u_2)=\frac{\left |L_{u1} \bigcap L_{u2}\right |+\left |D_{u1} \bigcap D_{u2}\right |-\left |L_{u1} \bigcap D_{u2}\right |-\left |D_{u1} \bigcap L_{u2}\right |}{\left |u_1\bigcup u_2 \right |}
$$

Whew! This looks a lot more complex than the original formula, but it's still quite simple! I promise! Now, in addition to finding the agreements between u<sub>1</sub> and u<sub>2</sub>, we're finding their disagreements! The agreements between u<sub>1</sub> and u<sub>2</sub> are the same as before. Their disagreements are conversely defined as the number of items that u<sub>1</sub> likes but u<sub>2</sub> dislikes and vice versa. All we do is subtract the number of disagreements from the number of agreements, and divide by the total number of items liked or disliked across the two users. Easy!

It is worth noting that the similiarity value calculated has a bounds of -1 and 1. You would have a -1.0 similarity value with your polar opposite (your evil twin that has rated the same items as you, but differently) and a 1.0 similarity value with your clone (you have both rated the same items in the same ways).

## Okay, read my mind!

Now that we can reduce the relationship between two people to a number, lets use that number to predict whether you'll like or dislike something. Neat! Let's say we want to predict how you'll feel about *thing*. We get every user in our system that has rated *thing* and start calculating a hive-mind sum. Feel free to fear the hive-mind sum, as the hive-mind sum demands your respect! If a user liked *thing*, we add your similarity value with them to the hive-mind sum. If they disliked it, we subtract instead! The idea behind this is that if someone with tastes similar to yours likes *thing*, you'll probably like it too. If they dislike it, you're less likely to enjoy *thing*. But if a user with tastes dissimilar to yours likes *thing*, you're LESS likely to hit that "Like" button and vice versa. Moving right along, we finally take this hive-mind sum and divide it by the total number of people that have rated *thing*. Done! Woah, what? That was easy! Look, more math!

$$
P(you, thing)=\frac{\sum_{i=1}^{n_L} J(you, u_i) - \sum_{i=1}^{n_D}J(you, u_i)}{n_L + n_D}
$$

In this equation: *thing* is the thing we want to know if *you* will like, *n<sub>L</sub>* is the number of users that have liked *thing*, and *n<sub>D</sub>* is the number of users that have disliked *thing*. Good? Good!

## Just show me the code!

Well, aren't we impatient? Fine. I suppose you've waited this long. Here's a simple pseudo-implementation of some sweet, sweet Jaccardian collaborative filtering. In Ruby, of course!

{% gist davidcelis/4bdbece8af6fe224de1a jaccardian.rb %}

This is nice and simple and is more or less the way I do things in [recommendable][recommendable] and [goodbre.ws][goodbre.ws]. I did, however, tweak the algorithm in one major way. For example, in that last stage of calculating the similarity values, I actually divide by `self.likes.size + self.dislikes.size`. With this change, the similarity value becomes dependent on the number of items that `self` has rated, but not the number of items that `user` has rated. As such, this makes their similarity values not be reflective:

{% gist davidcelis/4bdbece8af6fe224de1a not_reflective.rb %}

My reasoning behind this is that newer users who have not had a chance to submit likes and dislikes for many objects should not be punished for simply being new. Recommendations for new users can really suck! Say I've submitted ratings for five items, you've submitted ratings for fifty, and four of these items are the same. If we share the same ratings for three of those items, I want my similarity value for you to be high. I'm new here! It will potentially help me get better recommendations faster. You, on the other hand... You've seen things, man. You don't need handouts from the system. Your similarity value with me should be much lower.

## The Conclusioning

Clearly, the Jaccardian similarity coefficient is a very intuitive way to compare people when the rating system is binary. The other algorithms I mentioned are pretty cool too, but Likes/Dislikes and set math were just made for each other. They're like peanut butter and jelly. Bananas and Nutella. Bored people and reality television. It's a beautiful marriage that I hope will last forever, even if I wasn't invited to the wedding.

[goodbre.ws]: http://goodbre.ws/
[recommendable]: http://github.com/davidcelis/recommendable
[pearson]: http://en.wikipedia.org/wiki/Pearson_product-moment_correlation_coefficient
[euclidean]: http://en.wikipedia.org/wiki/Euclidean_distance
[cosine]: http://en.wikipedia.org/wiki/Cosine_similarity
[knn]: http://en.wikipedia.org/wiki/K-nearest_neighbor_algorithm

<script src="//cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"></script>
