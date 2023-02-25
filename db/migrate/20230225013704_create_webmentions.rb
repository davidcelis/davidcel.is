class CreateWebmentions < ActiveRecord::Migration[7.0]
  def change
    create_enum :webmention_status, %w[unprocessed verified failed]

    create_table :webmentions, id: :bigint, default: -> { "public.snowflake_id()" } do |t|
      t.string :source, null: false
      t.string :target, null: false

      t.enum :status, enum_name: :webmention_status, null: false, default: "unprocessed"

      t.text :html
      t.jsonb :mf2, null: false, default: {}

      t.timestamps

      t.index [:source, :target], unique: true
      t.index [:target, :status]
    end
  end
end
