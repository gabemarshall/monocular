class AddTaskTypeIdToJob < ActiveRecord::Migration[5.1]
  def self.up
    change_table :jobs do |t|
      t.integer :task_type_id
    end
  end

  def self.down
    change_table :jobs do |t|
      t.remove :task_type_id
    end
  end
end
