class IndexWebmentionsOnTypeAndStatus < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :webmentions, :status, algorithm: :concurrently
    add_index :webmentions, :type, algorithm: :concurrently

    # Add a general purpose index that we'd use to retrieve all webmentions for a post
    add_index :webmentions, [:post_id, :type], where: "status = 'verified'", algorithm: :concurrently
  end
end
