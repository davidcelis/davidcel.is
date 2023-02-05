class CreateSyndicationLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :syndication_links, id: :uuid do |t|
      t.references :post, null: false, foreign_key: true
      t.string :platform, null: false
      t.string :url, null: false

      t.timestamps
    end
  end
end
