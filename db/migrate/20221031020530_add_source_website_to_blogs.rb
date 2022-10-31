class AddSourceWebsiteToBlogs < ActiveRecord::Migration[7.0]
  def change
    add_column :blogs, :source_website, :string
  end
end
