class MediaAttachment < ApplicationRecord
  belongs_to :post

  has_one_attached :file
  delegate_missing_to :file
end
