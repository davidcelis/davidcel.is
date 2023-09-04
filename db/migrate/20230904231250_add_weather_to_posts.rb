class AddWeatherToPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :weather, :jsonb
  end
end
