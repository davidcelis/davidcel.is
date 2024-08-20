class AddHashtagsToPosts < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :posts, :hashtags, :string, array: true, null: false, default: []
    add_index :posts, :hashtags, using: :gin, algorithm: :concurrently
  end
end
