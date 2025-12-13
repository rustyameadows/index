class EntityUploadsController < ApplicationController
  before_action :require_login
  before_action :set_project
  before_action :set_entity

  def create
    upload_ids = Array(params[:upload_id] || params[:upload_ids]).reject(&:blank?)
    uploads = @project.uploads.where(id: upload_ids)

    uploads.each do |upload|
      @entity.entity_uploads.find_or_create_by(upload: upload)
    end

    redirect_to project_entity_path(@project, @entity), notice: "Uploads linked."
  end

  def destroy
    link = @entity.entity_uploads.find(params[:id])
    link.destroy
    redirect_to project_entity_path(@project, @entity), notice: "Upload unlinked."
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_entity
    @entity = @project.entities.find(params[:entity_id])
  end
end
