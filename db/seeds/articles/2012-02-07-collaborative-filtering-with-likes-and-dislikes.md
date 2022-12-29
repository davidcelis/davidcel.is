---
title: "Collaborative Filtering with Likes and Dislikes"
date: 2012-02-07 13:10
---

We’ve talked about some of the pitfalls of the [five-star rating system](https://davidcel.is/articles/why-i-hate-five-star-ratings/) and how a binary system based on likes and dislikes can be much better, but what does using this kind of rating system look like in practice? How can we take a user’s likes and dislikes and use them to generate helpful recommendations? The answer, as with the five-star system, is through collaborative filtering, but we can rely on a methodology better suited to a binary system!

<!--more-->

## Collaborative filtering

If you aren’t familiar with collaborative filtering, its a technique used in recommendation engines to predict (filter) the interest of a user by collecting data about the interests of many users (collaborating). There are many different types of collaborative filtering, but for our system of likes and dislikes, we’ll be focusing on memory-based collaborative filtering, which uses ratings submitted by users to calculate the similarity between those users.

Even within just the scope of memory-based collaborative filtering, there are a number of algorithms or techniques to calculate similarity. A few of the more widely used algorithms or formulae include [Euclidean Distance][euclidean], [Pearson’s Correlation][pearson], [Cosine-based vector similarity][cosine], and the [k-Nearest Neighbor algorithm][knn]. These are all well documented and multiple example implementations are available should you wish to know more. They’re all great for the heavily-used five-star system and, while they’d work fine for likes and dislikes, we have an interesting alternative that I feel is better suited! So let’s talk about an algorithm I don’t see used often but which works great for our binary system. Let’s talk about the Jaccard similarity coefficient!

## Jean-Luc Jaccard?

No, no, no; we’re talking about _Paul_ Jaccard, a botanist that performed research near the turn of the 20th century. Jaccard’s research led him to develop the _coefficient de communauté_, or what is known in English as the [Jaccard index](https://en.wikipedia.org/wiki/Jaccard_index) (or Jaccard similarity coefficient).[^1] The Jaccard index is a simple calculation of similarity between sample sets. Where the aforementioned collaborative filtering algorithms can quickly become mathematically complex, the Jaccard index is rather simple! It can be described as the size of the intersection between two binary sample sets divided by the size of the union between the same sample sets. Whew! That description might be a little difficult to follow, so here’s how to represent it in math:

$$
J(u_1,u_2)=\frac{\left |u_1 \bigcap u_2\right |}{\left |u_1\bigcup u_2 \right |}
$$

This formula can rather intuitively be used with likes and dislikes! Let’s say we’re comparing two users: u<sub>1</sub> and u<sub>2</sub>. How does one intersect two users? How does one union them? Well, we don’t want to intersect or union the people themselves; this isn’t Mary Shelly’s _Frankenstein_! If we’re using the Jaccard index for collaborative filtering, we want both of these operations to deal with the users’ ratings. Let’s say that the intersection is the set of items which both users have rated. The union would then be the combined set of items that _either_ u<sub>1</sub> _or_ u<sub>2</sub> has rated. But how does this work with the actual ratings? Let’s modify the formula a bit to deal with the likes and dislikes themselves:

$$
J(u_1,u_2)=\frac{\left |L_{u1} \bigcap L_{u2}\right |+\left |D_{u1} \bigcap D_{u2}\right |}{\left |u_1\bigcup u_2 \right |}
$$

Now we’re getting somewhere! What we’ve got now is looking more collaborative and filtery for sure. We find the number of items that both u<sub>1</sub> and u<sub>2</sub> like, add it to the number of items that both u<sub>1</sub> and u<sub>2</sub> dislike, and then divide that by the total number of different items that u<sub>1</sub> and u<sub>2</sub> have rated. This is a great start, but we can go even further to match users up.

## Birds of a feather flock together, and opposites repel

We may be defining our similarity as our agreed upon interests and disinterests, but what about our _disgreements_? If our shared likes and dislikes are important factors in calculating our similarity, we can use discrepancies in our ratings to incorporate _disimilarity_ into our calculations. To show you what I mean, let’s tweak the formula a bit more, shall we?

$$
J(u_1,u_2)=\frac{\left |L_{u1} \bigcap L_{u2}\right |+\left |D_{u1} \bigcap D_{u2}\right |-\left |L_{u1} \bigcap D_{u2}\right |-\left |D_{u1} \bigcap L_{u2}\right |}{\left |u_1\bigcup u_2 \right |}
$$

Whew! This looks a lot more complex than the original formula, but we can walk through it together. Now, in addition to finding the agreements between u<sub>1</sub> and u<sub>2</sub>, we’re finding their disagreements! The agreements between u<sub>1</sub> and u<sub>2</sub> are the same as before. Their _disagreements_ are conversely defined as the number of items that u<sub>1</sub> likes but u<sub>2</sub> dislikes and vice versa. All we do is subtract the number of disagreements from the number of agreements, and divide by the total number of items liked or disliked across the two users.

Previously, when we were calculating similarity only based on agreements, our coefficient would have been bounded between 0 and 1. However, now that we’re accounting for disagreements, our bounds have expanded to being between -1 and 1. You would have a -1.0 similarity value with your polar opposite (e.g. your evil twin that has rated the same items as you, but each one differently) and a 1.0 similarity value with a very fresh clone of yourself (you have both rated the same items in the same ways).

## Okay, read my mind!

Now that we can reduce the tender, loving relationship between two people to a cold, indifferent number, let’s use that number to predict whether you’ll like or dislike something. Neat! Let’s say we want to predict how you’ll feel about _thing_. We get every user in our system that has rated _thing_ and start calculating a kind of hive-mind sum. Don’t be afraid, though; this isn’t _really_ a hive mind or intelligent AI! Anyway, if a user liked _thing_, we add your similarity value with them to the sum. If they disliked it, we subtract instead! The idea behind this is that if someone with tastes similar to yours likes _thing_, you’ll probably like it too. If they dislike _thing_, you’re less likely to enjoy it. Likewise, if a user who has a low or negative similarity coefficient with you has rated _thing_, you’re likely to rate it in the opposite way. Finallym we take this sum and divide it by the total number of people that have rated _thing_. Done! Like before, let’s let the math speak too:

$$
P(you, thing)=\frac{\sum_{i=1}^{n_L} J(you, u_i) - \sum_{i=1}^{n_D}J(you, u_i)}{n_L + n_D}
$$

In this equation: _thing_ is the thing we want to know if _you_ will like, _n<sub>L</sub>_ is the number of users that have liked _thing_, and _n<sub>D</sub>_ is the number of users that have disliked _thing_.

## Math is cool but how about some code?

That’s fair. You’ve been very patient and I appreciate you reading all of that! Heck, even if you skipped all the way here, you’re here nonetheless. So here’s a little pseudo-implementation of Jaccardian collaborative filtering (in Ruby, of course)!

```ruby
require "set"

class User
  # The collections of objects this user likes and dislikes. These are both
  # best represented using a Set.
  attr_reader :likes, :dislikes

  def similarity_with(user)
    # Set#& is the set intersection operator.
    agreements = (self.likes & user.likes).size
    agreements += (self.dislikes & user.dislikes).size

    disagreements = (self.likes & user.dislikes).size
    disagreements += (self.dislikes & user.likes).size

    # Set#| is the set union operator
    all_items = (self.likes + self.dislikes) | (user.likes + user.dislikes)

    return (agreements - disagreements) / all_items.size.to_f
  end

  def prediction_for(item)
    sum = 0.0
    item.liked_by.each { |user| sum += self.similarity_with(user) }
    item.disliked_by.each { |user| sum -= self.similarity_with(user) }

    rated_by = (item.liked_by + item.disliked_by).size

    return sum / rated_by
  end
end
```

This is more or less the way I do things in [recommendable][recommendable] and, while it was still online, [goodbre.ws][goodbre.ws]. I did, however, tweak the algorithm in one major way. For example, in that last stage of calculating the similarity values, I actually divide by `self.likes.size + self.dislikes.size`. With this change, the similarity value becomes dependent on the number of items that `self` has rated, but not the number of items that `user` has rated. As such, this makes their similarity values not be reflective:

```ruby
self.similarity_with(user) == user.similarity_with(self)
# => false unless self.ratings.size == user.ratings.size
```

My reasoning behind this is that newer users who have not had a chance to submit likes and dislikes for many objects shouldn’t be punished for simply being new; recommendations for new users can be pretty bad! Say I’ve submitted ratings for five items, you’ve submitted ratings for fifty, and four of these items are the same. If we share the same ratings for three of those items, I want our similarity coefficient to be high. I’m new here, and it’ll potentially help me get better recommendations faster. On the other hand, your fifty ratings means you’ve seen things. You don’t really need the same jump start that I do, so your similarity value with me can stand to be lower.

## The Conclusioning

The Jaccard index can be a very intuitive way to compare people when your rating system is binary. The other algorithms I mentioned are pretty cool too, but likes, dislikes and set math were just made for each other. They’re like peanut butter and jelly. Bananas and Nutella™. Bored people and reality television. It’s a beautiful partnership that I hope can last forever.

[goodbre.ws]: https://github.com/davidcelis/goodbre.ws
[recommendable]: https://github.com/davidcelis/recommendable
[pearson]: https://en.wikipedia.org/wiki/Pearson_product-moment_correlation_coefficient
[euclidean]: https://en.wikipedia.org/wiki/Euclidean_distance
[cosine]: https://en.wikipedia.org/wiki/Cosine_similarity
[knn]: https://en.wikipedia.org/wiki/K-nearest_neighbor_algorithm

[^1]: Although this statistic is named for Paul Jaccard, it was actually first developed by geologist [Grove Karl Gilbert](https://en.wikipedia.org/wiki/Grove_Karl_Gilbert) in 1884; Jaccard independently developed and popularized the same statistic in 1912. It was then independently developed for a third time by T. Tanimoto in 1958, leading the statistic to be known occasionally as the Tanimoto index or Tanimoto coefficient.

<script type="text/javascript" id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js">
</script>
