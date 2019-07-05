class CreateServices < ActiveRecord::Migration[5.1]
  def self.up
    create_table :services do |t|
      t.string :ip
      t.integer :port
      t.text :banner
      t.text :body
      t.string :uri
      t.string :service_type
      t.string :hostname
      t.string :status_code
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :services
  end
end
