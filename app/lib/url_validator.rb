class URLValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless URI.parse(value).is_a?(URI::HTTP)
      record.errors.add(attribute, options[:message] || "is not a valid URL")
    end
  end
end
