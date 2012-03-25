if Rails.env == "development"


  # Lists options
  def list
    IO.read(__FILE__).scan(/#(.*)\n *def (.*)\n/).each do |m|
      puts m.last + " " * ( 10 - m.last.size ) + " - " + m.first
    end
    nil
  end
  

  # reload and makes new @p (project.new :url..)
  def rp
    reload!
    @p = Project.new :url => "https://github.com/regedor/Utils-menu"
  end
  

  # Run all and save to db (@p.run!) 
  def pr!
    @p.run!
  end

  # Prints  @p.rbp_report  
  def report
    @p.nbp_report
  end

  # Reloads console (reload!)
  def r
    reload!
  end
  
  # Counts projects saved (Project.count)
  def c
    Project.count
  end
  
  # Deletes all Projects          
  def destroy!
    Project.all.map &:destroy
  end
  
  # Try to run! again
  def try_again!
    Project.find_all_by_forks(nil).each do |a|
      begin 
        a.run!
      rescue 
        puts "ERROR HERE! #{a.url}"
      end
    end
  end

end
