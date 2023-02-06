require "rails_helper"

RSpec.describe SyndicateToMastodonJob, type: :job do
  subject(:job) { SyndicateToMastodonJob.new }

  context "with a Note" do
    let(:note) { Note.create!(content: "Hello, world!") }

    it "shares the note's content to Mastodon" do
      expect_any_instance_of(Mastodon::Client).to receive(:create_status)
        .with(content: "Hello, world!", idempotency_key: note.id)
        .and_call_original

      expect {
        VCR.use_cassette("create_mastodon_status") { job.perform(note.id) }
      }.to change {
        note.syndication_links.count
      }.by(1)

      syndication_link = note.syndication_links.first
      expect(syndication_link.platform).to eq("mastodon")
      expect(syndication_link.url).to eq("https://xoxo.zone/@ewdavidcelis/109815732381019049")
    end
  end

  context "with an Article" do
    let(:article) { Article.create!(title: "Hello, world!", content: "Nice day we're having.") }

    it "shares the Article's title and URL to Mastodon" do
      expect_any_instance_of(Mastodon::Client).to receive(:create_status)
        .with(content: "“Hello, world!”\n\nhttp://localhost:3000/articles/hello-world", idempotency_key: article.id)
        .and_call_original

      expect {
        VCR.use_cassette("create_mastodon_status") { job.perform(article.id) }
      }.to change {
        article.syndication_links.count
      }.by(1)

      syndication_link = article.syndication_links.first
      expect(syndication_link.platform).to eq("mastodon")
      expect(syndication_link.url).to eq("https://xoxo.zone/@ewdavidcelis/109815732381019049")
    end
  end
end
