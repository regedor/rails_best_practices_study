require 'fileutils'

class Project < ActiveRecord::Base


  #DELETEME
  #  Debug Method 
  #
  def set_url
    self.url ="https://github.com/regedor/Utils-menu"
  end


  #
  #  redefining destroy: deletes local repo associated with the project
  #
  def destroy
    system "rm -rf '#{self.repo_path}'"
    super
  end


  #
  # Run full analyse on project
  #
  def run!
    self.update_github_information
    self.update_best_practices_report if update_repo! #tenho de por a fazer cenas
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

  #####RAILS BEST PRACTICES


  #
  #  Runs best practices
  #
  def update_best_practices_report
    #require File.join(Dir.pwd, 'vendor/plugins/rails_best_practices/lib/rails_best_practices/lexicals'  )
    #require File.join(Dir.pwd, 'vendor/plugins/rails_best_practices/lib/rails_best_practices/prepares'  )
    #require File.join(Dir.pwd, 'vendor/plugins/rails_best_practices/lib/rails_best_practices/reviews'   )
    #require File.join(Dir.pwd, 'vendor/plugins/rails_best_practices/lib/rails_best_practices/core'      )
    #require File.join(Dir.pwd, 'vendor/plugins/rails_best_practices/lib/fileutils'                      )
    @options = {}
    @path    = repo_path

    RailsBestPractices::Core::Runner.base_path = @path
    @runner = RailsBestPractices::Core::Runner.new

    ["lexical", "prepare", "review"].each { |process| send(:process, process) }
    @runner.on_complete
    
    self.nbp_report = results_csv
  end


  # process lexical, prepare or reivew.
  #
  # get all files for the process, analyze each file,
  # and increment progress bar unless debug.
  #
  # @param [String] process the process name, lexical, prepare or review.
  def process(process)
    files = send("#{process}_files")
    files.each do |file|
      #debugger
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
 
      # Exclude files based on exclude regexes if the option is set.
      # @options[:exclude].each do |pattern|
      #   files = file_ignore(files, pattern)
      # end
 
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
 

  #
  # output results with csv format.
  #
  def results_csv 
    require 'csv'
    CSV.generate do |csv|
      csv << (["ProjectName"] + 
             @runner.results.map { |result| [result[:checker_name], "nr_file"             ]}.flatten)
      csv << (["ProjectName"] + 
             @runner.results.map { |result| [result[:error_count], result[:files_checked] ]}.flatten)
    end
  end

  def self.big_csv
    self.select('nbp_report').map(&:nbp_report).join '\n'
  end


end
