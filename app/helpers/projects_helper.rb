module ProjectsHelper
  def humanized_description(p) 
    if (p.nbp_report_to_hash['rbp_score'].to_i > 2) && (p.watchers + p.forks) < p.nbp_report_to_hash['rbp_score'].to_i * 30 && p.born_at > (Date.today - 1.year) # recent but good
      "#{p.name.capitalize} has #{p.watchers} watchers and #{p.forks} forks on GitHub." +
      "These are not big numbers for a project with a score of #{p.score}, however the GitHub repository was only created #{time_ago_in_words p.born_at} ago." +
      "The last update happened #{time_ago_in_words (Date.today - (p.updated_at.to_date - p.pushed_at).to_i.days)} before this analisys."
    elsif (p.nbp_report_to_hash['rbp_score'].to_i > 2) && (p.watchers + p.forks) > p.nbp_report_to_hash['rbp_score'].to_i * 100 # good forks
      "#{p.name.capitalize} has #{p.watchers} watchers and #{p.forks} forks on GitHub." +
      "This numbers match the hight level quality of the project." +
      "The repository was created #{time_ago_in_words p.born_at} ago " +
      "and the last update happened #{time_ago_in_words (Date.today - (p.updated_at.to_date - p.pushed_at).to_i.days)} before this analisys."
    elsif (p.nbp_report_to_hash['rbp_score'].to_i < 3) && p.pushed_at < (Date.today - 1.year) # old
      "#{p.name.capitalize} has #{p.watchers} watchers and #{p.forks} forks." +
      "The GitHub repository was created #{time_ago_in_words p.born_at} ago, but it had no activity for #{time_ago_in_words p.pushed_at} ago." +
      "This might explain the low score."
    else # normal
      "The repository was created #{time_ago_in_words p.born_at} ago, it has #{p.watchers} watchers and #{p.forks} forks on GitHub." +
      "The last updated happened #{time_ago_in_words p.pushed_at} ago."
    end
  end
end

