namespace :db do
  namespace :seed do
    desc "Loads the seed data from db/seeds/articles.rb"
    task articles: [:environment] do
      Kernel.silence_warnings { load "db/seeds/articles.rb" }
    end

    desc "Loads the seed data from db/seeds/notes/tweets.rb"
    task tweets: [:environment] do
      Kernel.silence_warnings { load "db/seeds/notes/tweets.rb" }
    end

    desc "Loads the seed data from db/seeds/notes/toos.rb"
    task toots: [:environment] do
      Kernel.silence_warnings { load "db/seeds/notes/toots.rb" }
    end

    desc "Loads the seed data from db/seeds/notes.rb"
    task notes: ["db:seed:tweets", "db:seed:toots"]
  end
end
