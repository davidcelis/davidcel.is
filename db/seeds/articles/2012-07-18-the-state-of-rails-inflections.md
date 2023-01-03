---
title: "The State of Rails Inflections"
date: 2012-07-18 16:30
updated: 2022-12-29 10:10
---

Ah, the Rails Inflector; one way or another, we all know and love it. This little part of ActiveSupport has a lot of responsibility in our Rails applications, after all! It’s used to determine table names, class names, our resourceful routes, foreign keys... It’s a small part of ActiveSupport, but it has a _huge_ footprint. Outside of Rails’ internal use of the Inflector, it also provides a lot of useful mechanisms for string manipulation to Rails developers. But how does the Inflector actually handle things like singularization and pluralization? English isn’t a regular language, after all!

<!--more-->

There are a lot of grammatical rules to consider when converting between the singular or plural form of various words, so what does the Inflector consider? There must be some magic involved, right? According to the documentation, Rails defines these inflections directly in ActiveSupport... `lib/active_support/inflections.rb` to be exact. Let’s take a looksy, shall we?

```ruby
#--
# Defines the standard inflection rules. These are the starting point for
# new projects and are not considered complete. The current set of inflection
# rules is frozen. This means, we do not change them to become more complete.
# This is a safety measure to keep existing applications from breaking.
#++
#--
# Defines the standard inflection rules. These are the starting point for
# new projects and are not considered complete. The current set of inflection
# rules is frozen. This means, we do not change them to become more complete.
# This is a safety measure to keep existing applications from breaking.
#++
module ActiveSupport
  Inflector.inflections(:en) do |inflect|
    inflect.plural(/$/, "s")
    inflect.plural(/s$/i, "s")
    inflect.plural(/^(ax|test)is$/i, '\1es')
    inflect.plural(/(octop|vir)us$/i, '\1i')
    inflect.plural(/(octop|vir)i$/i, '\1i')
    inflect.plural(/(alias|status)$/i, '\1es')
    inflect.plural(/(bu)s$/i, '\1ses')
    inflect.plural(/(buffal|tomat)o$/i, '\1oes')
    inflect.plural(/([ti])um$/i, '\1a')
    inflect.plural(/([ti])a$/i, '\1a')
    inflect.plural(/sis$/i, "ses")
    inflect.plural(/(?:([^f])fe|([lr])f)$/i, '\1\2ves')
    inflect.plural(/(hive)$/i, '\1s')
    inflect.plural(/([^aeiouy]|qu)y$/i, '\1ies')
    inflect.plural(/(x|ch|ss|sh)$/i, '\1es')
    inflect.plural(/(matr|vert|ind)(?:ix|ex)$/i, '\1ices')
    inflect.plural(/^(m|l)ouse$/i, '\1ice')
    inflect.plural(/^(m|l)ice$/i, '\1ice')
    inflect.plural(/^(ox)$/i, '\1en')
    inflect.plural(/^(oxen)$/i, '\1')
    inflect.plural(/(quiz)$/i, '\1zes')

    inflect.singular(/s$/i, "")
    inflect.singular(/(ss)$/i, '\1')
    inflect.singular(/(n)ews$/i, '\1ews')
    inflect.singular(/([ti])a$/i, '\1um')
    inflect.singular(/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)(sis|ses)$/i, '\1sis')
    inflect.singular(/(^analy)(sis|ses)$/i, '\1sis')
    inflect.singular(/([^f])ves$/i, '\1fe')
    inflect.singular(/(hive)s$/i, '\1')
    inflect.singular(/(tive)s$/i, '\1')
    inflect.singular(/([lr])ves$/i, '\1f')
    inflect.singular(/([^aeiouy]|qu)ies$/i, '\1y')
    inflect.singular(/(s)eries$/i, '\1eries')
    inflect.singular(/(m)ovies$/i, '\1ovie')
    inflect.singular(/(x|ch|ss|sh)es$/i, '\1')
    inflect.singular(/^(m|l)ice$/i, '\1ouse')
    inflect.singular(/(bus)(es)?$/i, '\1')
    inflect.singular(/(o)es$/i, '\1')
    inflect.singular(/(shoe)s$/i, '\1')
    inflect.singular(/(cris|test)(is|es)$/i, '\1is')
    inflect.singular(/^(a)x[ie]s$/i, '\1xis')
    inflect.singular(/(octop|vir)(us|i)$/i, '\1us')
    inflect.singular(/(alias|status)(es)?$/i, '\1')
    inflect.singular(/^(ox)en/i, '\1')
    inflect.singular(/(vert|ind)ices$/i, '\1ex')
    inflect.singular(/(matr)ices$/i, '\1ix')
    inflect.singular(/(quiz)zes$/i, '\1')
    inflect.singular(/(database)s$/i, '\1')

    inflect.irregular("person", "people")
    inflect.irregular("man", "men")
    inflect.irregular("child", "children")
    inflect.irregular("sex", "sexes")
    inflect.irregular("move", "moves")
    inflect.irregular("zombie", "zombies")

    inflect.uncountable(%w(equipment information rice money species series fish sheep jeans police))
  end
end
```

As you can see from the comment, this file is mostly no longer touched; the last commit that _did_ touch this file was in 2017, but Rails hasn’t accepted changes to the rules since possibly Rails 2 or even Rails 1. So, although this is a snapshot of Rails’ inflections in the most recent release (`7.0.4`), it’s unlikely to ever change. And, well... Yikes. This brings me to what I really want to discuss: the state of Rails’ Singularization and Pluralization rules. I think it’s a mess.

## Pluralization in English is not regular

There are only a few basic rules in English for pluralization. Because we’re speaking in terms of text, I’ll try to keep these rules based on characters rather than sounds. However, one important rule does depend on "[sibilant](http://en.wikipedia.org/wiki/Sibilant)" sounds, which are defined as a sound made by directing air through the sharp edge of your teeth and your tongue (i.e. "sh", "ss", "dge", etc.). While prevalent, this can be difficult to detect in text and there are definitely edge cases.

### The rules

* If the word ends with a "sibilant" sound, the plural form ends with "es" (dish → dishes or kiss → kisses) or "s" if the word already ends with an "e" (such as fridge → fridges or judge → judges)
* Most words that end with an "o" preceded by a consonant pluralize as "oes" (potato → potatoes, avocado → avocadoes).
* Most words that end with a "y" preceded by a consonant pluralize as "ies" (lady → ladies, berry → berries)

Aside from these rules, however, all other regular plurals are achieved by adding an "s".

### Some exceptions

* Words of foreign origin are exempt from the "oes" rule (piano → pianos, zero → zeros, kimono → kimonos).
* Proper nouns that end with a y are exempt from the "ies" rule (Germany → Germanys, Cody → Codys).

These are just two sets of exceptions, however, and these are moreso rules that are exceptions to other rules. English pluralization is riddled with other exceptions that are inconsistent:

* Some words that end in an "f" have that "f" mutated to a "v" during pluralization (calf → calves, shelf → shelves, leaf → leaves) due in part to the evolution of old/middle English to standard English.
* Some words with double "o"s replace those "o"s with "e"s (goose → geese, foot → feet).
* Many words are both singular and plural (buffalo, money, sheep, series, fish, coffee) and are therefore uncountable.
* Some words can even be pluralized _multiple ways_ depending on context (indices/indexes, staffs/staves)! That’s a case that the Rails Inflector can never hope to get right.
* And, of course, some words are just plain irregular (child → children, man → men, mouse → mice, datum → data, etc.).

How can Rails hope to consider all of these exceptions when English is such an irregular and fluid language? How should Rails handle the edge cases and irregularities? The answer is simple: it shouldn’t.

## The inflector should be based on rules, not exceptions

The current inflections that Rails defines are riddled with both rules and exceptions. The file has become such a mess, and so many people were submitting pull requests ([#7086](https://github.com/rails/rails/pull/7086) [#345](https://github.com/rails/rails/pull/345) [#3930](https://github.com/rails/rails/pull/3930) [#3910](https://github.com/rails/rails/pull/3910) [#6820](https://github.com/rails/rails/pull/6820) [#2457](https://github.com/rails/rails/pull/2457) and the list goes on and on and on...) to either fix inflections or add new ones, that inflections in Rails are now frozen. From the documentation for `ActiveSupport::Inflector`:

> The Rails core team has stated patches for the inflections library will not be accepted in order to avoid breaking legacy applications which may be relying on errant inflections. If you discover an incorrect inflection and require it for your application, you’ll need to correct it yourself.

This makes sense, but I feel that this situation is unfortunate, and it seem like the Rails core team agrees. Don’t get me wrong, many of these pull requests _should_ be closed. A common response to these patches is "Rails cannot possibly include all inflections by default," and I completely agree. Rails has already found itself in a situation where it has defined way too many inflections that are exceptions or irregularities, such as ox → oxen, crisis → crises, and the aforementioned case of index → indices (even though this pluralization is purely contextual). _Many_ of the "rules" defined in Rails’ inflections are really exceptions. Some of these exceptions are narrow and affect only one or two words. Some of the exceptions admittedly make sense, but should instead be defined as irregularities rather than singular/plural inflections. I’ll gloss over why some of the current inflections _don’t_ make sense:

* axis → axes, testis → testes: these are special rules that should be defined as irregularities.
* octopus → octopi, virus → viri: these special rules are actually disputed, as octopuses and viruses are more used and accepted.
* octopi → octopi, viri → viri, oxen → oxen: these words are not singular, so pluralization should not even be attempted.
* buffalo → buffaloes, tomato → tomatoes, hive → hives, alias → aliases, status → statuses: these all follow regular pluralization rules and shouldn’t have needed to be defined as special cases.
* matrix → matrices, vertex → vertices, index → indices: indices and indexes are both accepted depending on the context, and it’s likely that neither matrices nor vertices are used enough in Rails applications to warrant a special rule.
* quiz → quizzes: similar to the above; this is an irregularity.
* mouse → mice, louse → lice: exceptional words that are unlikely see the light of day in most Rails applications.
* news ⇄ news: this could have just been defined as an uncountable rather than a pluralization rule.
* ox → oxen: A special rule that should be an irregularity, but is also unlikely to be used in most Rails applications

As you can see, we have numerous inflections defined as special cases even though they follow a regular pluralization rule. Many shouldn’t be defined in the first place, even as irregularities instead of singularization/pluralization rules. Many involve words that most Rails applications will never need to use. The "Zombie" rule, for example, was only added because a website devoted to Rails tutorials, [Rails for Zombies](http://railsforzombies.org/), noticed that [generators were singularizing "zombies" as "zomby"](https://github.com/rails/rails/pull/2457) due to "zombies" being irregular. Perhaps a better idea would have been to take that as an opportunity to provide a quick lesson on inflections to new Rails users. Oh, and don’t even get me started on the ridiculously added, archaic plural form of "cow": `inflect.irregular('cow', 'kine')`

Of course, there are some exceptions and irregularities that make sense to define. To name a few, "child" is a frequently-used term in programming and computer science, "person" is a somewhat frequently-used model name in Rails applications, and "half" or "life" are also used frequently in programming depending on the area. I won’t argue that they should be defined within the framework as irregularities.

## Why not `.unfreeze`, or at least fix, the default inflections?

When I originally wrote this post, Rails 4.0 was on its way, which I thought would be a great opportunity to clean up the default inflections. Isn’t a major release the perfect time to eschew the worry of breaking existing applications for the betterment of the framework? Rails is a huge piece of software; any upgrades should be done with caution. In fact, most major (or even _minor_) version bumps of Rails now involve detailed instructions and tools to help users upgrade their applications. Do inflections really need to be backwards compatible as long as the CHANGELOG, documentation, and upgrade guides/tools make these changes clear? Upgrading Rails versions has required extreme caution for many years now.

## Until then, a better set of defaults:

Until Rails core decides its time to clean up inflections, I’ve provided a more sane set of singularization and pluralization rules in the form of a gem:

[davidcelis/inflections](https://github.com/davidcelis/inflections)

Here’s the difference:

* 4 pluralization rules (down from 21)
* 5 singularization rules (down from 27)
* 3 irregularities (down from 7)
* 1 uncountable (down from 10)

Ahhh... Much better.
