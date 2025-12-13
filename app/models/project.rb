class Project < ApplicationRecord
  belongs_to :user
  has_many :uploads, dependent: :destroy
  has_many :entities, dependent: :destroy

  validates :title, presence: true
end
