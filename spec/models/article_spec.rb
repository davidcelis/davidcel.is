require "rails_helper"

RSpec.describe Article, type: :model do
  subject(:article) { Article.new(title: "Hello, world!", content: "This is my very first post.") }

  describe "validations" do
    it "must have a title" do
      expect(article).to be_valid

      article.title = ""

      expect(article).not_to be_valid
      expect(article.errors[:title]).to include("can't be blank")
    end

    it "must have content" do
      expect(article).to be_valid

      article.content = ""

      expect(article).not_to be_valid
      expect(article.errors[:content]).to include("can't be blank")
    end
  end

  describe "slug generation" do
    it "generates a slug on creation" do
      expect(article.slug).to be_nil

      article.save!

      expect(article.slug).to eq("hello-world")
    end

    it "does not change the slug on update" do
      article.save!

      expect(article.slug).to eq("hello-world")

      article.update!(title: "Goodbye, world!")

      expect(article.slug).to eq("hello-world")
    end

    it "uses the entire title as the slug" do
      article.update!(title: "This is a longer title that won't be truncated")

      expect(article.slug).to eq("this-is-a-longer-title-that-wont-be-truncated")
    end
  end

  describe "HTML rendering" do
    before do
      article.update!(content: <<~CONTENT)
        # Chunky Bacon

        Today, I'd _love_ to talk about **chunky bacon**. But what _is_ chunky bacon? Based on the name, one could assume that chunky bacon is:

        1. Chunky
        2. Bacon

        But don't take my word for it! Let's ask some ~mischevious~ adorable cartoon foxes from [Why's Poignant Guide to Ruby](https://poignant.guide/)

        ![chunky bacon](https://poignant.guide/images/the.foxes-4f.png)

        > Woohoo! I don't know what chunky bacon is, but we did it! We're in the book!

        Well! I'm not sure what to make of that. I'll just leave you with one more part of the poignant guide:

        ```ruby
        2.times {
          print "Yes, I've used chunky bacon in my examples, but never again!"
        }
        ```
      CONTENT
    end

    it "renders the content as HTML" do
      expect(article.html).to eq(<<~HTML.strip)
        <h1>Chunky Bacon</h1>
        <p>Today, I’d <em>love</em> to talk about <strong>chunky bacon</strong>. But what <em>is</em> chunky bacon? Based on the name, one could assume that chunky bacon is:</p>
        <ol>
        <li>Chunky</li>
        <li>Bacon</li>
        </ol>
        <p>But don’t take my word for it! Let’s ask some <del>mischevious</del> adorable cartoon foxes from <a href="https://poignant.guide/" target="_blank" rel="nofollow noopener noreferrer">Why’s Poignant Guide to Ruby</a></p>
        <p><img src="https://poignant.guide/images/the.foxes-4f.png" alt="chunky bacon" /></p>
        <blockquote>
        <p>Woohoo! I don’t know what chunky bacon is, but we did it! We’re in the book!</p>
        </blockquote>
        <p>Well! I’m not sure what to make of that. I’ll just leave you with one more part of the poignant guide:</p>
        <pre><code class="language-ruby">2.times {
          print &quot;Yes, I've used chunky bacon in my examples, but never again!&quot;
        }
        </code></pre>
      HTML
    end
  end
end
