if Rails.env == "development"
    
  def list
    puts " r   - reload and makes new project (doesn not save) "
    puts " pr! - run all and save the nproject                 "
    puts " c   - counts projects saved                         "
    puts " d!  - Deletes all Projects                          "
    puts " b   - Show the nproject rbp_report                  "
    nil
  end
  
  def r
    reload!
    @p = Project.new :url => "https://github.com/regedor/Utils-menu"
    @p.update_owner_and_name
  end
  
  def pr!
    @p.run!
  end
  
  def c
    Project.count
  end
  
  def d!
    Project.all.map &:destroy
  end
  
  def b
    @p.nbp_report
  end
end
