class CreateThreadsCredentials < ActiveRecord::Migration[7.1]
  def change
    create_table :threads_credentials do |t|
      t.string :access_token, null: false
      t.timestamp :expires_at, null: false

      t.timestamps
    end
  end
end
