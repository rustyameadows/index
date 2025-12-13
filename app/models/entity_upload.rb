class EntityUpload < ApplicationRecord
  belongs_to :entity
  belongs_to :upload

  validates :upload_id, uniqueness: { scope: :entity_id }
end
