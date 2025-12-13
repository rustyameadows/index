class NotesController < ApplicationController
  before_action :require_login
  before_action :set_project
  before_action :set_note, only: %i[show edit update destroy]

  def index
    @notes = @project.notes.order(updated_at: :desc)
    @note = Note.new
  end

  def show
    @backlinks = NoteReference.where(referent: @note).includes(:note)
    @entity_backlinks = NoteReference.where(referent_type: "Entity", referent_id: @note.id)
  end

  def new
    @note = @project.notes.new
  end

  def edit; end

  def create
    @note = @project.notes.new(note_params.merge(user: current_user))
    if @note.save
      redirect_to project_note_path(@project, @note), notice: "Note created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @note.update(note_params)
      redirect_to project_note_path(@project, @note), notice: "Note updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @note.destroy
    redirect_to project_notes_path(@project), notice: "Note deleted."
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_note
    @note = @project.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:title, :slug, :body)
  end
end
