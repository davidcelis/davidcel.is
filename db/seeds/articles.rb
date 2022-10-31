Dir[Rails.root.join("db", "seeds", "articles", "*.md")].each do |file|
  metadata = YAML.load_file(file)

  article = Article.find_or_initialize_by(title: metadata["title"])
  article.created_at = Time.use_zone("America/Los_Angeles") { Time.parse(metadata["date"]) }
  article.id = ActiveRecord::Base.connection.select_value("SELECT public.snowflake_id('#{article.created_at}')")
  article.content = File.read(file).sub(/\A---(.|\n)*?---/, "").strip

  article.save!
end
