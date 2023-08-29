class AddPlaces < ActiveRecord::Migration[7.0]
  def change
    create_table :places, id: :bigint, default: -> { "public.snowflake_id()" } do |t|
      t.string :name, null: false
      t.string :category
      t.point :coordinates, null: false, index: {using: :gist}
      t.string :apple_maps_id

      t.timestamps
    end

    add_reference :posts, :place, type: :bigint
  end
end
