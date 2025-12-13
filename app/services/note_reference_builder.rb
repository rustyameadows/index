class NoteReferenceBuilder
  TOKEN_REGEX = /\[\[(.+?)\]\]/

  def initialize(note)
    @note = note
    @project = note.project
  end

  def rebuild!
    NoteReference.transaction do
      @note.note_references.delete_all
      parse_tokens.each do |ref|
        @note.note_references.create!(referent: ref)
      end
    end
  end

  private

  def parse_tokens
    tokens = extract_tokens
    tokens.map { |tok| resolve_token(tok) }.compact
  end

  def extract_tokens
    @note.body&.to_plain_text&.scan(TOKEN_REGEX)&.flatten || []
  end

  def resolve_token(token)
    trimmed = token.strip
    case trimmed
    when /\AEntity:(.+)\z/i
      by_name(Entity, Regexp.last_match(1))
    when /\AUpload:(\d+)\z/i
      @project.uploads.find_by(id: Regexp.last_match(1))
    when /\ANote:(.+)\z/i
      by_slug_or_title(Note.for_project(@project), Regexp.last_match(1))
    else
      by_name(Entity, trimmed)
    end
  end

  def by_name(klass, name)
    scope = klass == Entity ? @project.entities : klass
    scope.find_by("LOWER(name) = ?", name.downcase)
  end

  def by_slug_or_title(scope, key)
    scope.find_by(slug: key.parameterize) || scope.find_by("LOWER(title) = ?", key.downcase) || scope.find_by(id: key)
  end
end
