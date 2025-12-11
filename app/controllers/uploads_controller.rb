class UploadsController < ApplicationController
  before_action :require_login
  before_action :set_project
  before_action :set_upload, only: %i[show download]

  def show; end

  def create
    @upload = @project.uploads.build(user: current_user)
    attach_file_and_metadata(@upload, upload_params[:file])

    if @upload.save
      redirect_to project_path(@project), notice: "File uploaded."
    else
      @uploads = @project.uploads.order(created_at: :desc).includes(file_attachment: :blob)
      render "projects/show", status: :unprocessable_entity
    end
  end

  def download
    if @upload.file.attached?
      redirect_to rails_blob_url(@upload.file, disposition: "attachment")
    else
      redirect_to project_path(@project), alert: "File not found."
    end
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_upload
    @upload = @project.uploads.find(params[:id])
  end

  def upload_params
    params.require(:upload).permit(:file)
  end

  def attach_file_and_metadata(upload, file_param)
    return unless file_param

    upload.file.attach(file_param)
    upload.original_filename = file_param.original_filename
    upload.content_type = file_param.content_type
    upload.byte_size = file_param.size
    upload.uploaded_at = Time.current
  end
end
