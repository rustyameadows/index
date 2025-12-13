class NoteReference < ApplicationRecord
  belongs_to :note

  belongs_to :referent, polymorphic: true
end
