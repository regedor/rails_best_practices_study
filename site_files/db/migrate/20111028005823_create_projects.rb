class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string    :url

      t.string    :owner 
      t.string    :name 

      t.integer   :forks 
      t.integer   :watchers 
      t.float     :score 
      t.integer   :size 

      t.boolean   :private 
      t.string    :homepage 
      t.text      :description 
      t.boolean   :fork 
      t.boolean   :has_wiki 
      t.boolean   :has_issues 
      t.integer   :open_issues 
      t.date      :pushed_at 
      t.date      :born_at 

      t.text      :nbp_report

      t.timestamps
    end
  end
end
