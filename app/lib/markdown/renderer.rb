module Markdown
  class Renderer < CommonMarker::HtmlRenderer
    def link(node)
      out('<a href="', node.url, '"')
      out(' title="', node.title, '"') if node.title.present?

      if node.url.start_with?("http") && remote_url?(node.url)
        out(' target="_blank" rel="nofollow noopener noreferrer"')
      end

      out(">", :children, "</a>")
    end

    private

    def remote_url?(url)
      !URI(url).host.end_with?("davidcel.is")
    end
  end
end
