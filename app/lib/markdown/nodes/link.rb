module Markdown
  module Nodes
    class Link < CommonMarker::Node
      def self.from_url(url)
        scheme = url.match(%r{^https?://})[0]
        url_without_scheme = url.gsub(%r{^https?://(?:www\.)?}, "")
        display_url = url_without_scheme.truncate(30, omission: "")
        rest_of_url = url_without_scheme[display_url.length..]

        new(:link).tap do |node|
          node.url = url
          node.title = url

          node.append_child(CommonMarker::Node.new(:inline_html).tap { |n| n.string_content = %(<span class="hidden">) })
          node.append_child(CommonMarker::Node.new(:text).tap { |n| n.string_content = scheme })
          node.append_child(CommonMarker::Node.new(:inline_html).tap { |n| n.string_content = %(</span>) })
          node.append_child(CommonMarker::Node.new(:inline_html).tap { |n| n.string_content = %(<span#{' class="ellipsis"' if rest_of_url.present?}>) })
          node.append_child(CommonMarker::Node.new(:text).tap { |n| n.string_content = display_url })
          node.append_child(CommonMarker::Node.new(:inline_html).tap { |n| n.string_content = %(</span>) })

          if rest_of_url.present?
            node.append_child(CommonMarker::Node.new(:inline_html).tap { |n| n.string_content = %(<span class="hidden">) })
            node.append_child(CommonMarker::Node.new(:text).tap { |n| n.string_content = rest_of_url })
            node.append_child(CommonMarker::Node.new(:inline_html).tap { |n| n.string_content = %(</span>) })
          end
        end
      end

      def self.from_mention(username, domain)
        new(:link).tap do |node|
          node.url = "https://#{domain}/@#{username}"
          node.title = "#{username}@#{domain}"

          node.append_child(CommonMarker::Node.new(:text).tap { |n| n.string_content = "@#{username}" })
        end
      end
    end
  end
end