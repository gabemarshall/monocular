class CreateJobs < ActiveRecord::Migration[5.1]
  def self.up
    create_table :jobs do |t|
      t.string :target
      t.boolean :is_expired
      t.string :schedule
      t.string :arguments
      t.string :uuid
      t.string :add_tasks
      t.datetime :datetime
      t.string :duration
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :jobs
  end
end
