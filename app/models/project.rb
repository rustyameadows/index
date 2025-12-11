class Project < ApplicationRecord
  belongs_to :user
  has_many :uploads, dependent: :destroy

  validates :title, presence: true
end
