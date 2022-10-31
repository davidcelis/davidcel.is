class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts, id: :bigint, default: -> { "public.snowflake_id()" } do |t|
      t.string :type, null: false, index: true

      t.string :title
      t.string :slug, null: false, index: true

      t.text :content, null: false
      t.text :html, null: false

      t.timestamps

      # For most posts, our primary key is enough to load the record. However,
      # articles are the only posts that have titles and a more formal URL
      # structure (/:type/:year/:month/:day/:slug). For example:
      #
      #   https://davidcel.is/articles/2012/10/03/stop-validating-email-with-regex/
      #
      # The following index is to support this.
      t.index [:type, :slug, :created_at], unique: true

      # For listing posts, our default is that we'll show all types ordered by
      # their time-relative UUID. Posts might end up being scoped by type so,
      # because our time-sorting can use the Primary Key, a simple index on
      # type is enough to support this.
    end
  end
end
