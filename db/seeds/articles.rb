ActiveRecord::Base.record_timestamps = false

Dir[Rails.root.join("db", "seeds", "articles", "*.md")].each do |file|
  metadata = YAML.load_file(file)

  article = Article.find_or_initialize_by(title: metadata["title"])
  article.created_at = Time.use_zone("America/Los_Angeles") { Time.zone.parse(metadata["date"]) }
  article.updated_at = Time.use_zone("America/Los_Angeles") { Time.zone.parse(metadata.fetch("updated", metadata["date"])) }
  article.id ||= ActiveRecord::Base.connection.select_value("SELECT public.snowflake_id('#{article.created_at}')")
  article.content = File.read(file).sub(/\A---(.|\n)*?---/, "").strip

  article.save!

  if article.previous_changes.any?
    puts "Updated Article: #{article.title}"
  end
end

ActiveRecord::Base.record_timestamps = true
