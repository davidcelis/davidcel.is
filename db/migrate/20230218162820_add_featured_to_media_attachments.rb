class AddFeaturedToMediaAttachments < ActiveRecord::Migration[7.0]
  def change
    add_column :media_attachments, :featured, :boolean, null: false, default: false, index: true
  end
end
