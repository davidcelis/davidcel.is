class AddProcessedToMediaAttachments < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :media_attachments, :processed, :boolean, null: false, default: false, index: true

    add_index :media_attachments, [:post_id, :processed], where: "processed = true", algorithm: :concurrently, name: "index_processed_media_attachments_on_post_id"

    reversible do |dir|
      dir.up do
        MediaAttachment.update_all(processed: true)
      end
    end
  end
end
