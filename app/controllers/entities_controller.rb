class EntitiesController < ApplicationController
  before_action :require_login
  before_action :set_project
  before_action :set_entity, only: %i[show edit update destroy]
  before_action :set_entity_with_toggle, only: %i[toggle_pin]

  def index
    @entities = @project.entities.order(Arel.sql("pinned DESC"), :category, :name)
    @entity = Entity.new
  end

  def show
    @entity_uploads = @entity.uploads.includes(file_attachment: :blob).order(created_at: :desc)
    @available_uploads = @project.uploads.where.not(id: @entity.upload_ids).order(created_at: :desc)
    @note_backlinks = NoteReference.where(referent: @entity).includes(:note)
  end

  def new
    @entity = @project.entities.new
  end

  def create
    @entity = @project.entities.new(entity_params)
    if @entity.save
      redirect_to project_entity_path(@project, @entity), notice: "Entity created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @entity.update(entity_params)
      redirect_to project_entity_path(@project, @entity), notice: "Entity updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @entity.destroy
    redirect_to project_entities_path(@project), notice: "Entity deleted."
  end

  def toggle_pin
    @entity.update!(pinned: !@entity.pinned)
    redirect_back fallback_location: project_entities_path(@project), notice: (@entity.pinned? ? "Entity pinned." : "Entity unpinned.")
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_entity
    @entity = @project.entities.find(params[:id])
  end

  def set_entity_with_toggle
    @entity = @project.entities.find(params[:id])
  end

  def entity_params
    params.require(:entity).permit(:name, :category, :description)
  end
end
