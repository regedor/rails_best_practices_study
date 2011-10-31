class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      # Main fields
      t.string    :url
      t.string    :owner 
      t.string    :name 

      # Github fields
      t.integer   :forks 
      t.integer   :watchers 
      t.float     :score 
      t.integer   :size 

      # More Github fields
      t.boolean   :private 
      t.string    :homepage 
      t.text      :description 
      t.boolean   :fork 
      t.boolean   :has_wiki 
      t.boolean   :has_issues 
      t.integer   :open_issues 
      t.date      :pushed_at 
      t.date      :born_at     # Created at (on github's API)

      # Best practices report representation
      t.text      :nbp_report

      # fields for running logic
      t.boolean   :marked_for_run,    default: true
      t.integer   :priority,          default: 0

      t.timestamps
    end
  end
end
