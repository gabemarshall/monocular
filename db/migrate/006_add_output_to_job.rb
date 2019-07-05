class AddOutputToJob < ActiveRecord::Migration[5.1]
  def self.up
    change_table :jobs do |t|
      t.text :output
    end
  end

  def self.down
    change_table :jobs do |t|
      t.remove :output
    end
  end
end
