class AddCoordinatesToPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :coordinates, :point
  end
end
