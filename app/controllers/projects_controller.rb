class ProjectsController < ApplicationController
  before_action :require_login
  before_action :set_project, only: :show

  def index
    @projects = current_user.projects.order(created_at: :desc)
    @project = Project.new
  end

  def show
    @upload = Upload.new
    @uploads = @project.uploads.order(created_at: :desc).includes(file_attachment: :blob)
  end

  def create
    @project = current_user.projects.build(project_params)
    if @project.save
      redirect_to @project, notice: "Project created."
    else
      @projects = current_user.projects.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:title, :description)
  end
end
