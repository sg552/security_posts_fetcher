class CreateBlogs < ActiveRecord::Migration[7.0]
  def change
    create_table :blogs do |t|
      t.string :title
      t.text :content
      t.string :author
      t.string :image_url

      t.timestamps null: false
    end
  end
end
