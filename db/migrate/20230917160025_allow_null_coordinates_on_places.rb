class AllowNullCoordinatesOnPlaces < ActiveRecord::Migration[7.0]
  def change
    # Drop the NOT NULL constraint on the coordinates column in favor of a CHECK
    # constraint that ensures either `coordinates` are present when `apple_maps_id`
    # is also present. This allows us to create generic Place records for posts
    # that aren't explicit check-ins.
    change_column_null :places, :coordinates, true
    add_check_constraint :places, "coordinates IS NOT NULL OR apple_maps_id IS NULL"
  end
end
