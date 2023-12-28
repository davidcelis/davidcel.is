class DeleteFromBlueskyJob < ApplicationJob
  def perform(rkey)
    client.delete_post(rkey)
  ensure
    client.sign_out!
  end

  private

  def client
    @client ||= ATProto::Client.new(
      identifier: Rails.application.credentials.dig(:at_proto, :identifier),
      password: Rails.application.credentials.dig(:at_proto, :app_password)
    )
  end
end
