class AddLinkSupportToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :link_data, :jsonb
  end
end
