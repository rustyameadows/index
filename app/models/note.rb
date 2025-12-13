class Note < ApplicationRecord
  belongs_to :project
  belongs_to :user

  has_rich_text :body
  has_many :note_references, dependent: :destroy

  before_validation :set_slug
  after_commit :rebuild_references, on: %i[create update]

  validates :slug, presence: true, uniqueness: { scope: :project_id }

  scope :for_project, ->(project) { where(project_id: project.id) }

  def set_slug
    self.slug = (slug.presence || title.presence || "note-#{SecureRandom.hex(4)}").parameterize
  end

  def rebuild_references
    NoteReferenceBuilder.new(self).rebuild!
  end
end
