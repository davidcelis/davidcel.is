namespace :posts do
  desc "Assign the correct type to existing webmentions"
  task regenerate_html: [:environment] do
    Post.find_each do |post|
      html = post.update_html
      post.update_columns(html: html)

      puts "Updated HTML for post #{post.id}"
    end
  end

  desc "Backfills hashtags for existing posts"
  task backfill_hashtags: [:environment] do
    Post.find_each do |post|
      hashtags = post.parse_hashtags
      post.update_columns(hashtags: hashtags)

      puts "Backfilled hashtags for post #{post.id} (#{post.hashtags.join(", ")})"
    end
  end
end
