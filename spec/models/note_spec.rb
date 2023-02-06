require "rails_helper"

RSpec.describe Note, type: :model do
  subject(:note) { Note.new(content: "Hello, world!") }

  describe "validations" do
    it "cannot have a title" do
      expect(note).to be_valid

      note.title = "Hello, world!"

      expect(note).not_to be_valid
      expect(note.errors[:title]).to include("must be blank")
    end

    it "must have content" do
      expect(note).to be_valid

      note.content = ""

      expect(note).not_to be_valid
      expect(note.errors[:content]).to include("can't be blank")
    end
  end

  describe "syndication" do
    it "enqueues a job to syndicate the post to Mastodon on creation" do
      allow(SyndicateToMastodonJob).to receive(:perform_async)

      note.save!
      note.update!(content: "Updated note")

      expect(SyndicateToMastodonJob).to have_received(:perform_async).with(note.id).once
    end
  end

  describe "slug generation" do
    it "generates a slug on creation" do
      expect(note.slug).to be_nil

      note.save!

      expect(note.slug).to eq("hello-world")
    end

    it "does not change the slug on update" do
      note.save!

      expect(note.slug).to eq("hello-world")

      note.update!(content: "Goodbye, world!")

      expect(note.slug).to eq("hello-world")
    end

    it "only uses the first 5 words" do
      note.update!(content: "This is a long post that should be truncated")

      expect(note.slug).to eq("this-is-a-long-post")
    end

    it "strips markdown from the slug" do
      note.update!(content: "~Just~ _look_ **at** `this` [post](https://example.com), ![y'all](https://example.com/image.png)")

      expect(note.slug).to eq("just-look-at-this-post")
    end
  end

  describe "HTML rendering" do
    before do
      note.update!(content: <<~CONTENT)
        Variables which begin with a **dollar sign** are _global_.

        `$x`, `$1`, `$chunky` and `$CHunKY_bACOn` are examples.
      CONTENT
    end

    it "renders the content as HTML" do
      expect(note.html).to eq(<<~HTML.strip)
        <p>Variables which begin with a <strong>dollar sign</strong> are <em>global</em>.</p>
        <p><code>$x</code>, <code>$1</code>, <code>$chunky</code> and <code>$CHunKY_bACOn</code> are examples.</p>
      HTML
    end
  end
end
