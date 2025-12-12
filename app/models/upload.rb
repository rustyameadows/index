class Upload < ApplicationRecord
  belongs_to :project
  belongs_to :user
  belongs_to :parent_upload, class_name: "Upload", optional: true
  has_many :derived_uploads, class_name: "Upload", foreign_key: :parent_upload_id, dependent: :nullify

  has_one_attached :file

  validates :file, presence: true
  validates :original_filename, presence: true
  validates :content_type, presence: true
  validates :byte_size, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def image?
    file.attached? && file.image?
  end

  def processing_metadata
    self[:processing_metadata] || {}
  end
end
