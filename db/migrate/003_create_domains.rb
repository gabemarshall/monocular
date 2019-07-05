class CreateDomains < ActiveRecord::Migration[5.1]
  def self.up
    create_table :domains do |t|
      t.string :dns_name
      t.string :dns_record
      t.string :dns_record_type
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :domains
  end
end
