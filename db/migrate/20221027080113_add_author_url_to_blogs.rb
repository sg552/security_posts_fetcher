class AddAuthorUrlToBlogs < ActiveRecord::Migration[7.0]
  def change
    add_column :blogs, :author_url, :string
  end
end
