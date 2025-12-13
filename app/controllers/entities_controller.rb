class EntitiesController < ApplicationController
  before_action :require_login
  before_action :set_project
  before_action :set_entity, only: %i[show edit update destroy]

  def index
    @entities = @project.entities.order(:name)
    @entity = Entity.new
  end

  def show
    @entity_uploads = @entity.uploads.includes(file_attachment: :blob).order(created_at: :desc)
    @available_uploads = @project.uploads.where.not(id: @entity.upload_ids).order(created_at: :desc)
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

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_entity
    @entity = @project.entities.find(params[:id])
  end

  def entity_params
    params.require(:entity).permit(:name, :category, :description)
  end
end
