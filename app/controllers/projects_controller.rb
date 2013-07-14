class ProjectsController < ApplicationController


  # GET /projects
  # GET /projects.json
  def index
    respond_to do |format|
      format.html do
        @project  = Project.new
        @projects = Project.select("id, name, forks, watchers, owner, url, score").order("score DESC")
      end
      format.json do
        @projects = Project.all
        render json: @projects 
      end
      format.csv  { render text: Project.big_csv }
    end
  end


  # GET /projects/1
  # GET /projects/1.json
  def show
    @project = Project.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @project }
    end
  end

  # GET /projects/new.json
  def new
    respond_to do |format|
      format.json { render json: @project }
    end
  end


  # POST /projects
  # POST /projects.json
  def create
    @projects = Project.select("id, name, forks, watchers, owner, url, score").order("score DESC")
    respond_to do |format|
      params[:_projects][:urls] && ( @project = Project.create({:url => params[:_projects][:urls].split(",").first}) )
      unless @project.errors
        format.html { render action: "index", notice: 'Project was successfully created.' }
        format.json { render json: @project, status: :created, location: @project }
      else
        format.html { render action: "index", error: 'Invalid URL.' }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end


  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    respond_to do |format|
      format.html { redirect_to projects_url }
      format.json { head :ok }
    end
  end
end
