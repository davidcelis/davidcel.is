class DeleteFromMastodonJob < ApplicationJob
  def perform(status_id)
    client.delete_status(status_id)
  end

  private

  def client
    @client ||= Mastodon::Client.new
  end
end
