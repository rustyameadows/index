class Upload < ApplicationRecord
  belongs_to :project
  belongs_to :user

  has_one_attached :file

  validates :file, presence: true
  validates :original_filename, presence: true
  validates :content_type, presence: true
  validates :byte_size, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
