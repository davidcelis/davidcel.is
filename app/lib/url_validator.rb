class URLValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    begin
      return if self.class.parse(value)
    rescue URI::InvalidURIError
    end

    record.errors.add(attribute, options[:message] || "is not a valid URL")
  end

  def self.parse(url)
    url = URI::DEFAULT_PARSER.escape(url) unless url.ascii_only?

    URI.parse(url)
  end
end
