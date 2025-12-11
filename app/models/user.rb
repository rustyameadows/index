class User < ApplicationRecord
  has_secure_password

  has_many :projects, dependent: :destroy
  has_many :uploads, dependent: :destroy

  validates :email, presence: true, uniqueness: true
end
