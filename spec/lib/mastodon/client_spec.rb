require "rails_helper"

RSpec.describe Mastodon::Client do
  let(:access_token) { "MASTODON_ACCESS_TOKEN" }

  subject(:client) { Mastodon::Client.new(access_token: access_token) }

  describe "#verify_credentials" do
    around { |e| VCR.use_cassette("verify_mastodon_credentials", &e) }

    subject(:verification) { client.verify_credentials }

    it "returns a basic response verifying authentication" do
      expect(verification["name"]).to eq("davidcel.is (development)")
      expect(verification["website"]).to eq("http://localhost:3000/")
      expect(verification["vapid_key"]).to eq("BPZuo5Id68qYgAebi3KQZ66LWpynqjR0kfz1YbIlpYklNkYKRIKYqayNJTeX1x-69xx83r-6QQogtcoquHn-yXQ=")
    end

    context "when provided with a bad access token" do
      around { |e| VCR.use_cassette("unauthorized_mastodon_credentials", &e) }

      let(:access_token) { "BAD_MASTODON_ACCESS_TOKEN" }

      it "raises an error" do
        expect { verification }.to raise_error(Faraday::UnauthorizedError)
      end
    end
  end
end
