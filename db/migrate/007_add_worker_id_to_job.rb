class AddWorkerIdToJob < ActiveRecord::Migration[5.1]
  def self.up
    change_table :jobs do |t|
      t.integer :worker_id
    end
  end

  def self.down
    change_table :jobs do |t|
      t.remove :worker_id
    end
  end
end
