class AddBlogUrlToBlogs < ActiveRecord::Migration[7.0]
  def change
    add_column :blogs, :blog_url, :string
  end
end
