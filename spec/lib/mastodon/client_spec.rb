require "rails_helper"

RSpec.describe Mastodon::Client do
  let(:access_token) { "MASTODON_ACCESS_TOKEN" }

  subject(:client) { Mastodon::Client.new(access_token: access_token) }

  describe "#create_status" do
    it "creates a new status" do
      status = VCR.use_cassette("create_mastodon_status") do
        client.create_status(content: "Hello, world!")
      end

      expect(status["id"]).to eq("109815732381019049")
      expect(status["content"]).to eq("<p>Hello, world!</p>")
      expect(status["visibility"]).to eq("public")
    end

    context "when provided with an idempotency key" do
      let(:idempotency_key) { 1621339875439543547 }

      it "creates a new status, only once" do
        VCR.use_cassette("create_mastodon_status_with_idempotency_key") do
          first_status = client.create_status(
            content: "This is a test status that was created with an Idempotency Key.",
            idempotency_key: idempotency_key
          )

          second_status = VCR.use_cassette("create_mastodon_status_with_idempotency_key_retry") do
            client.create_status(
              content: "This is a test status that was created with an Idempotency Key.",
              idempotency_key: idempotency_key
            )
          end

          expect(first_status).to eq(second_status)
        end
      end
    end
  end

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
