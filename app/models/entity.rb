class Entity < ApplicationRecord
  CATEGORIES = %w[building person organization artwork event other].freeze

  belongs_to :project
  has_many :entity_uploads, dependent: :destroy
  has_many :uploads, through: :entity_uploads

  validates :name, presence: true, uniqueness: { scope: :project_id }
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  scope :pinned, -> { where(pinned: true) }
end
