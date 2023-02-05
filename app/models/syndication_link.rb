class SyndicationLink < ApplicationRecord
  belongs_to :post

  validates :url, format: {with: URI::DEFAULT_PARSER.make_regexp(%w[http https])}
end
