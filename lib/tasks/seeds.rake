namespace :db do
  namespace :seed do
    %w[articles notes].each do |name|
      desc "Loads the seed data from db/seeds/#{name}.rb"
      task name.to_sym => [:environment] do
        load "db/seeds/#{name}.rb"
      end
    end
  end
end
