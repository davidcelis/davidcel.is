class AddPlaces < ActiveRecord::Migration[7.0]
  def change
    create_table :places, id: :bigint, default: -> { "public.snowflake_id()" } do |t|
      t.string :name, null: false
      t.string :category # pointOfInterestCategory

      t.string :street # fullThoroughfare
      t.string :city # locality
      t.string :state # administrativeArea
      t.string :state_code # administrativeAreaCode
      t.string :postal_code # postCode
      t.string :country # country
      t.string :country_code # countryCode

      t.point :coordinates, null: false, index: {using: :gist} # coordinate

      t.string :apple_maps_id # muid
      t.string :apple_maps_url # _wpURL

      # Temporary, for migration purposes. The backfill involves reverse geocoding
      # and manual address correction for places that have closed or moved, so this
      # lets me backfill in batches by skipping places that have already been added.
      t.string :foursquare_id

      t.timestamps
    end

    add_reference :posts, :place, type: :bigint
  end
end
