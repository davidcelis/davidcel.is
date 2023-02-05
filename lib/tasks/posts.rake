namespace :posts do
  desc "Updates the HTML for all posts"
  task update_html: :environment do
    Post.find_each do |post|
      post.update_html

      if post.html_changed?
        puts "Updating post #{post.id}"
        post.save
      else
        puts "Skipping post #{post.id} (unchanged)"
      end
    end
  end
end
