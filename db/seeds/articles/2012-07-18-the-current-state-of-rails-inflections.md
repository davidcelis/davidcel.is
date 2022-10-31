---
layout: post
title: "The Current State of Rails Inflections"
date: 2012-07-18 16:30
categories: [programming, ruby, rails]
redirect_from:
  - /blog/2012/07/18/the-current-state-of-rails-inflections/
---

_UPDATE: I've provided a better set of inflections in the form of a gem. If you agree with my sentiment here, check it out at the end of this post._

Ah, the Rails Inflector; we all know and love it. This little part of ActiveSupport has a lot of responsibility in our Rails applications, after all. It affects table names, class names, our resourceful routes, foreign keys... It's a great part of ActiveSupport. Not only does much of Rails depend on the Inflector, but it provides useful mechanisms for string manipulation to users.

But how does the Inflector actually handle singularization and pluralization? English is not a regular language. There are a lot of grammatical rules to consider when converting between the two, so what does the Inflector consider? There must be some magic involved, right? According to the documentation, Rails defines these inflections directly in ActiveSupport... `lib/active_support/inflections.rb` to be exact. Let's take a looksy, shall we?

{% gist davidcelis/68028a6c8067d5be1939 inflections.rb %}

This is a snapshot of Rails' inflections in the master branch (4.0.0.beta) at the time of writing this post and... Well... Yikes. This brings me to what I really want to discuss: the state of Rails' Singularization and Pluralization rules. I think it's a mess.

## Pluralization in English is not regular

There are only a few basic rules in English for pluralization. Because we're speaking in terms of text, I'll try to keep these rules based on characters rather than sounds. However, one important rule does depend on "[sibilant](http://en.wikipedia.org/wiki/Sibilant)" sounds, which are defined as a sound made by directing air through the sharp edge of your teeth and your tongue (i.e. 'sh', 'ss', 'dge', etc.). While prevalent, this can be difficult to detect in text and there are definitely edge cases.

### The rules

* If the word ends with a "sibilant" sound, the plural form ends with 'es' (dish → dishes or kiss → kisses) or 's' if the word already ends with an 'e' (such as fridge → fridges or judge → judges)
* Most words that end with an 'o' preceded by a consonant pluralize as 'oes' (potato → potatoes, avocado → avocadoes).
* Most words that end with a 'y' preceded by a consonant pluralize as 'ies' (lady → ladies, berry → berries)

Aside from these rules, however, all other regular plurals are achieved by adding an 's'.

### Some exceptions

* Words of foreign origin are exempt from the 'oes' rule (piano → pianos, zero → zeros, kimono → kimonos).
* Proper nouns that end with a y are exempt from the 'ies' rule (Germany → Germanys, Cody → Codys).

These are just two sets of exceptions, however, and these are moreso rules that are exceptions to other rules. English pluralization is riddled with other exceptions that are inconsistent:

* Some words that end in an 'f' have that 'f' mutated to a 'v' during pluralization (calf → calves, shelf → shelves, leaf → leaves) due in part to the evolution of old/middle English to standard English.
* Some words with double 'o's replace those 'o's with 'e's (goose → geese, foot → feet).
* Many words are both singular and plural (buffalo, money, sheep, series, fish, coffee) and are therefore uncountable.
* Some words can even be pluralized _multiple ways_ depending on context (indices/indexes, staffs/staves)! That's a case that the Rails Inflector can never hope to get right.
* And, of course, some words are just plain irregular (child → children, man → men, mouse → mice, datum → data, etc.).

How can Rails hope to consider all of these exceptions when English is such an irregular and fluid language? How should Rails handle the edge cases and irregularities? The answer is simple: it shouldn't.

## The inflector should be based on rules, not exceptions

The current inflections that Rails defines are riddled with both rules and exceptions. The file has become such a mess, and so many people were submitting pull requests ([#7086](https://github.com/rails/rails/pull/7086) [#345](https://github.com/rails/rails/pull/345) [#3930](https://github.com/rails/rails/pull/3930) [#3910](https://github.com/rails/rails/pull/3910) [#6820](https://github.com/rails/rails/pull/6820) [#2457](https://github.com/rails/rails/pull/2457) and the list goes on and on and on...) to either fix inflections or add new ones, that inflections in Rails are now frozen. From the documentation for `ActiveSupport::Inflector`:

> The Rails core team has stated patches for the inflections library will not be accepted in order to avoid breaking legacy applications which may be relying on errant inflections. If you discover an incorrect inflection and require it for your application, you'll need to correct it yourself.

I believe that the Rails core team members have shot themselves in the feet with this one. Don't get me wrong, many of these pull requests _should_ be closed. A common response to these patches is "Rails cannot possibly include all inflections by default." Awesome. I totally agree. But this is hypocritical, considering Rails has already defined many inflections that are exceptions or irregularities, such as ox → oxen, crisis → crises, and the aforementioned case of index → indices (even though this pluralization is purely contextual). Many of the "rules" defined in Rails' inflections are really exceptions. Some of these exceptions are narrow and affect only one or two words. Some of the exceptions admittedly make sense, but should instead be defined as irregularities rather than singular/plural inflections. I'll gloss over why some of the current inflections _don't_ make sense:

* axis → axes, testis → testes: these are special rules that should be defined as irregularities.
* octopus → octopi, virus → viri: these special rules are actually disputed, as octopuses and viruses are more used and accepted.
* octopi → octopi, viri → viri, oxen → oxen: these words are not singular, so pluralization should not even be attempted.
* buffalo → buffaloes, tomato → tomatoes, hive → hives, alias → aliases, status → statuses: these all follow regular pluralization rules and shouldn't have needed to be defined as special cases.
* matrix → matrices, vertex → vertices, index → indices: indices and indexes are both accepted depending on the context, and it's likely that neither matrices nor vertices are used enough in Rails applications to warrant a special rule.
* quiz → quizzes: similar to the above; this is an irregularity.
* mouse → mice, louse → lice: words that will never see the light of day in Rails applications.
* news ⇄ news: this could have just been defined as an uncountable rather than a pluralization rule.
* ox → oxen: A special rule that should be an irregularity, but will also likely never be used in Rails applications

Clearly, something is amiss here. Rails core team members say that Rails can not include all inflections and that exceptions should be defined by the user in the inflections initializer generated with every new Rails application. I agree, but that's not the practice I'm seeing here. Rails' inflections are riddled with poorly defined singularization and pluralization rules that are not even rules in the first place.

Some of the inflections I referred to above are defined as special cases even though they follow a regular pluralization rule. Many shouldn't be defined in the first place, even as irregularities instead of singularization/pluralization rules. When was the last time you saw an application using buffalo, tomato, mouse, louse, ox, or octopus as a model? The "Zombie" rule was only added because a website devoted to Rails tutorials, [Rails for Zombies](http://railsforzombies.org/), noticed that generators were [singularizing "zombies" as "zomby"](https://github.com/rails/rails/pull/2457) due to "zombies" being irregular. Perhaps a better idea would have been to take that as an opportunity to provide a quick lesson on inflections to new Rails users.

Oh, and don't even get me started on the ridiculously added, archaic plural form of "cow": `inflect.irregular('cow', 'kine')`

Of course, there are some exceptions and irregularities that make sense to define. To name a few, "child" is a frequently-used term in programming and computer science, "person" is a somewhat frequently-used model name in Rails applications, and "half" or "life" are also used frequently in programming depending on the area. I won't argue that they should be defined within the framework as irregularities.

## Rails 4.0 is coming - it's time to .unfreeze inflections

With Rails 4.0 on its way, isn't now a good time to clean up the inflections? Isn't a major release the perfect time to eschew the worry of breaking existing applications for the betterment of the framework? Rails is a huge piece of software; any upgrades should be done with caution. Users should be expected to read the CHANGELOG when upgrading even from minor versions, and they should read the upgrade guides that Rails provides with each minor version bump. Inflections do not need to be backwards compatible. We should fix the inflections that are clearly exceptions and not rules, note it in the CHANGELOG and upgrade guides, and move on with our lives. Developers who blindly upgrade their Rails versions are asking for hurt, and freezing an area of the framework that needs improvement is the wrong approach.

## Until then, a better set of defaults:

Until Rails core decides its time to clean up inflections, I've provided a more sane set of singularization and pluralization rules in the form of a gem:

[davidcelis/inflections](https://github.com/davidcelis/inflections)

Here's the difference:

* 4 pluralization rules (down from 21)
* 5 singularization rules (down from 27)
* 3 irregularities (down from 7)
* 1 uncountable (down from 10)

Ahhh. Much better.
