class AddTypeToWebmentions < ActiveRecord::Migration[7.1]
  def change
    create_enum :webmention_type, %w[reply like repost mention]

    add_column :webmentions, :type, :webmention_type, default: "mention"
  end
end
