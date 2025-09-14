class URLValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    begin
      return if URI.parse(value).is_a?(URI::HTTP)
    rescue URI::InvalidURIError
    end

    record.errors.add(attribute, options[:message] || "is not a valid URL")
  end
end
