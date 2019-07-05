class CreateTokens < ActiveRecord::Migration[5.1]
  def self.up
    create_table :tokens do |t|
      t.string :name
      t.string :key
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :tokens
  end
end
