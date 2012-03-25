require 'fileutils'

class Project < ActiveRecord::Base

  validates :url, uniqueness: true

  after_save { self.send_later(:run!) if self.marked_for_run }

  #def results
  #  @results ||= JSON.parse(self.nbp_report)
  #end


  #
  #  redefining destroy: deletes local repo associated with the project
  #
  def destroy
    #system "rm -rf '#{self.repo_path}'"
    super
  end


  #
  # Run full analyse on project
  #
  def run!
    self.update_github_information
    self.update_best_practices_report if update_repo! #tenho de por a fazer cenas
    self.marked_for_run = false
    self.save!
  end


  #
  #  Fechtes github information about the project, and updates the model fields
  #
  def update_github_information
    self.update_owner_and_name
    github = GitHub.repository(owner, name)
    self.watchers     =  github.watchers
    self.forks        =  GitHub.forks(owner, name).size
    self.watchers     =  github.watchers
    self.score        =  github.score
    self.size         =  github.size
    self.private      =  github.private
    self.homepage     =  github.homepage
    self.description  =  github.description
    self.fork         =  github.fork
    self.has_wiki     =  github.has_wiki
    self.has_issues   =  github.has_issues
    self.open_issues  =  github.open_issues
    self.pushed_at    =  github.pushed_at
    self.born_at      =  github.created_at
  end


  #
  #  Clones(if it's the first time) and pulls the repository from github to local folder.
  #
  #  #FIXME deveria retornar true or false consoante houve alterações
  #
  def update_repo!
    if File.exist? repo_path 
      system "cd '#{repo_path}'; git pull"
    else
      FileUtils.mkdir_p(File.dirname repo_path)
      system "git clone '#{self.url}' '#{repo_path}'"
      return true
    end
  end


  #
  #  Local path for repo
  #
  #  @return [String] repo path
  def repo_path
    return nil unless self.owner and self.name
    @repo_path ||= File.join(Dir.pwd, "projects", self.owner, self.name)
  end


  #
  #  Updates project owner and name based on the URL
  #
  def update_owner_and_name
    url   = self.url.split "/"
    self.name  = url[-1]
    self.owner = url[-2]
  end

  # FIXME this should be a class that returns the csv header
  #def csv_header
  #  CSV.generate do |csv|
  #    csv << (Project.attribute_names.sort - ["nbp_report"] + @runner.results.map do
  #      |result| [result[:checker_name], "Number of files analyzed"]
  #    end.flatten)
  #  end
  #end


  #
  #  Renders a big csv containing projects information
  #
  def self.big_csv
    self.first.nbp_report.split("\n").first + "\n" +
    self.select('nbp_report').find_all do |p|
      !p.nbp_report.blank?
    end.map{|p|p.nbp_report.split("\n").last}.join("\n")
  end


  #
  # #FIXME needs a lot of validations
  #
  def self.create_from_urls(urls)
    urls.each do |url|
      self.create :url => url
    end
    return true
  end


##################################
#####  RAILS BEST PRACTICES  #####
##################################
  include RailsBestPractices

  #
  #  Runs best practices
  #
  def update_best_practices_report
    @options = {}
    @path    = repo_path

    Core::Runner.base_path = @path
    @runner = Core::Runner.new

    ["lexical", "prepare", "review"].each { |process| send(:process, process) }
    @runner.on_complete
    
    #self.nbp_report = json_results
    self.nbp_report = results_csv
  end


  # ignore specific files.
  #
  # @param [Array] files
  # @param [Regexp] pattern files match the pattern will be ignored
  # @return [Array] files that not match the pattern
  def self.file_ignore files, pattern
    files.reject { |file| file.index(pattern) }
  end
 

  #
  # output results in json format.
  #
  def json_results
    @runner.results.map do |result|
      result[:error_ratio] = result[:error_count].to_f/(result[:files_checked]+1)
      result
    end.to_json
  end


  #
  # output results in csv format.
  #
  def results_csv 
    require 'csv'
    CSV.generate do |csv|
      csv << (Project.attribute_names.sort - ["nbp_report"] + @runner.results.map do
        |result| [result[:checker_name], "Number of files analyzed"]
      end.flatten)
      csv << ((Project.attribute_names.sort - ["nbp_report"]).map { |attr| self.send(attr) } +
        @runner.results.map { |result| [result[:error_count], result[:files_checked] ]}.flatten
      )
    end
  end














    # process lexical, prepare or reivew.
    #
    # get all files for the process, analyze each file.
    #
    # @param [String] process the process name, lexical, prepare or review.
    def process(process)
      files = send("#{process}_files")
      files.each do |file|
        @runner.send("#{process}_file", file)
      end
    end

    # get all files for prepare process.
    #
    # @return [Array] all files for prepare process
    def prepare_files
      @prepare_files ||= begin
        ['app/models', 'app/mailers', 'db/schema.rb', 'app/controllers'].inject([]) { |files, name|
          files += expand_dirs_to_files(File.join(@path, name))
        }.compact
      end
    end

    # get all files for review process.
    #
    # @return [Array] all files for review process
    def review_files
      @review_files ||= begin
        files = expand_dirs_to_files(@path)
        files = file_sort(files)

        # By default, tmp, vender, spec, test, features are ignored.
        ['vendor', 'spec', 'test', 'features', 'tmp'].each do |pattern|
          files = file_ignore(files, "#{pattern}/") unless @options[pattern]
        end

        files.compact
      end
    end

    alias :lexical_files :review_files

    # expand all files with extenstion rb, erb, haml and builder under the dirs
    #
    # @param [Array] dirs what directories to expand
    # @return [Array] all files expanded
    def expand_dirs_to_files *dirs
      extensions = ['rb', 'erb', 'rake', 'rhtml', 'haml', 'builder']

      dirs.flatten.map { |entry|
        next unless File.exist? entry
        if File.directory? entry
          Dir[File.join(entry, '**', "*.{#{extensions.join(',')}}")]
        else
          entry
        end
      }.flatten
    end


    # sort files, models first, then mailers, and sort other files by characters.
    #
    # models and mailers first as for prepare process.
    #
    # @param [Array] files
    # @return [Array] sorted files
    def file_sort files
      models = []
      mailers = []
      files.each do |a|
        if a =~ Core::Check::MODEL_FILES
          models << a
        end
      end
      files.each do |a|
        if a =~ Core::Check::MAILER_FILES
          mailers << a
        end
      end
      files.collect! do |a|
        if a =~ Core::Check::MAILER_FILES || a =~ Core::Check::MODEL_FILES
          #nil
        else
          a
        end
      end
      files.compact!
      models.sort
      mailers.sort
      files.sort
      return models + mailers + files
    end

    # ignore specific files.
    #
    # @param [Array] files
    # @param [Regexp] pattern files match the pattern will be ignored
    # @return [Array] files that not match the pattern
    def file_ignore files, pattern
      files.reject { |file| file.index(pattern) }
    end



end
