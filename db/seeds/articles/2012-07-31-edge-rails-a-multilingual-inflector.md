---
layout: post
title: "Edge Rails 4.0: A Multilingual Inflector"
date: 2012-07-31 09:50
categories: [programming, ruby, rails, edge rails]
redirect_from:
  - /blog/2012/07/31/edge-rails-a-multilingual-inflector/
---

Here's a sneak peak at an upcoming enhancement for `ActiveSupport::Inflector` in Rails 4.0. The Inflector is the part of Rails responsible for a good amount of the cool stuff you can do with Strings: pluralization, singularization, titleization, humanization, tableization... The list goes on. Rails uses these methods extensively to map between, say, Model names, Controller names, and the Model's table name.

Currently, the Inflector can handle only one set of rules at a time. Rails provides a lengthy list of singularization and pluralization rules for English, but what if somebody wants to specify how certain words in a foreign language (say Spanish) should be pluralized? In Rails 3, they have two options: they can define the words as irregularities in `config/initializers/inflections.rb` or put them into locale files. The former is bad because it involves mixing two languages into one set of rules, and the latter can lead to large, cluttered locale files when internationalizing a website. In Rails 4, however, I'm happy to offer a better solution for Rails developers in the process of internationalization: the Inflector is now multilingual. It can manage a complete set of inflection rules for each locale!

Rails will still only provide a list of inflections in English. However, it's now much easier to specify your own set of rules (or have them provided to you via a gem) for additional locales. You can, as previously, specify these rules in `config/initializers/inflections.rb`:

{% gist davidcelis/d2397231af75c486c309 es.rb %}

After specifying our ruleset for Spanish, we can fire up a Rails console and see it in action:

{% gist davidcelis/d2397231af75c486c309 pry_session.rb %}

The Inflector will still default to English and use `:en` as the locale unless specified, as opposed to using the application's `I18n.default_locale`. This is to avoid breaking applications that have been wired internally to use English pluralization rules for mapping between Model, Controller, and table names.

Go ahead and browse the [commit on GitHub](https://github.com/rails/rails/commit/7db0b073fec6bc3e6f213b58c76e7f43fcc2ab97).

### Where can I get rules for other locales?

I'm proud to offer a solution for this too! I've created a gem called [Inflections](https://github.com/davidcelis/inflections) that I'm hoping can serve as a central repository for inflection rules of all locales. Unfortunately, I'm not a master of linguistics. Aside from English, I am only comfortable with Spanish, and so that's the only additional set of inflection rules I have provided thus far (aside from a shorter list of English inflections that I believe to be stripped to the essentials). If you or anybody you know are a Rails developer and fluent in another language, please consider [forking Inflections](https://github.com/davidcelis/inflections/fork_select), making a list of inflections (`lib/inflections/<locale>.rb`) with tests (`test/<locale>_test.rb`) and [opening a pull request](https://github.com/davidcelis/inflections/pull/new/master).
