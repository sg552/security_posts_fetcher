class CreateProxies < ActiveRecord::Migration[7.0]
  def change
    create_table :proxies do |t|
      t.string :ip
      t.integer :port
      t.string :external_ip
      t.datetime :expiration_time

      t.timestamps null: false
    end
  end
end
