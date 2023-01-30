class CreateMediaAttachments < ActiveRecord::Migration[7.0]
  def change
    create_table :media_attachments, id: :bigint, default: -> { "public.snowflake_id()" } do |t|
      t.references :post, null: false, foreign_key: true
      t.text :description

      t.timestamps
    end
  end
end
