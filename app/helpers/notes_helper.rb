module NotesHelper
  LINK_REGEX = /\[\[(.+?)\]\]/

  def render_note_body(note)
    html = note.body&.to_s || ""
    html.gsub(LINK_REGEX) do |_match|
      token = Regexp.last_match(1)
      link_for_token(note.project, token)
    end.html_safe
  end

  private

  def link_for_token(project, token)
    trimmed = token.strip
    case trimmed
    when /\AEntity:(.+)\z/i
      entity = project.entities.find_by("LOWER(name) = ?", Regexp.last_match(1).downcase)
      entity ? link_to(entity.name, project_entity_path(project, entity)) : missing_link(trimmed)
    when /\AUpload:(\d+)\z/i
      upload = project.uploads.find_by(id: Regexp.last_match(1))
      upload ? link_to(upload.original_filename, project_upload_path(project, upload)) : missing_link(trimmed)
    when /\ANote:(.+)\z/i
      key = Regexp.last_match(1)
      note = project.notes.find_by(slug: key.parameterize) || project.notes.find_by(id: key)
      note ? link_to(note.title.presence || note.slug, project_note_path(project, note)) : missing_link(trimmed)
    else
      entity = project.entities.find_by("LOWER(name) = ?", trimmed.downcase)
      entity ? link_to(entity.name, project_entity_path(project, entity)) : missing_link(trimmed)
    end
  end

  def missing_link(token)
    content_tag(:span, token, style: "color:#c00;", title: "Unresolved link")
  end
end
