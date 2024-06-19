class RefreshThreadsCredentialsJob < ApplicationJob
  def perform
    Threads::Credential.sole.refresh!
  rescue ActiveRecord::RecordNotFound
    # I haven't done the OAuth handshake yet, so there's nothing to do.
  end
end
