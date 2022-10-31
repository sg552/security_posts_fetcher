class CreateCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :categories do |t|
      t.string :name
      t.integer :blog_id

      t.timestamps null: false
    end
  end
end
