class CreateSpecialColumns < ActiveRecord::Migration[7.0]
  def change
    create_table :special_columns do |t|
      t.string :name
      t.string :source_website

      t.timestamps null: false
    end
  end
end
