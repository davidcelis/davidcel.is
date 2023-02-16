class RemoveProcessedFromMediaAttachments < ActiveRecord::Migration[7.0]
  def change
    remove_column :media_attachments, :processed, :boolean, null: false, default: false, index: true

    reversible do |dir|
      dir.down do
        MediaAttachment.update_all(processed: true)
      end
    end
  end
end
