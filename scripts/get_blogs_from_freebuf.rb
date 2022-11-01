ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

i = 1

loop do
  @logger = Logger.new("#{Rails.root}/log/get_blogs_from_anquanmaibo.log")
  response = HTTParty.get "https://www.freebuf.com/fapi/frontend/home/article?page=#{i}&limit=20&type=1&day=7&category=%E7%B2%BE%E9%80%89"
  #response = HTTParty.get "https://www.freebuf.com/fapi/frontend/home/article?page=#{i}"
  @logger.info response.body
  body = JSON.parse(response.body)
  temp_blogs = body["data"]["list"]
  @logger.info temp_blogs
  temp_blogs.each do |temp_blog|
    #https://www.freebuf.com/articles/348356.html
    puts '===='
    url = "https://www.freebuf.com/articles/#{temp_blog["ID"]}.html"
    puts url
    blog_local = Blog.where('blog_url = ?', url).first
    if blog_local.blank?
      title = temp_blog['post_title']
      created_at = temp_blog['post_date']
      #https://www.freebuf.com/author/%E6%96%97%E8%B1%A1%E7%A7%91%E6%8A%80%E5%AE%98%E6%96%B9
      author_url = "https://www.freebuf.com/author/#{temp_blog['post_author']}"
      remote_image_url = temp_blog['column_post_picture']
      image_name = remote_image_url.gsub('/', '_').gsub(':', '')
      `wget -cO - "#{remote_image_url}" > "public/blog_images/#{image_name}"`
      image_url = "###MY_IMAGE_SITE###/images/#{image_name}"
      category = temp_blog['category']
      author = temp_blog['username']
      views = temp_blog['read_count'].to_i
      @logger.info "=== url: #{url} title: #{title} created_at: #{created_at} author_url: #{author_url} image_url: #{image_url} category: #{category} author:#{author} views:#{views}"
      blog = Blog.create blog_url: url, author: author, views: views, title: title, created_at: created_at, image_url: image_url, source_website: 'freebuf', author_url: author_url
      category_local = Category.where('name = ? and blog_id = ?', category, blog.id).first
      if category_local.blank?
        Category.create name: category, blog_id: blog.id
      end
    end
  end
  i = i + 1
  @logger.info "=== i: #{i}"
  if i >10
    break
  end
end
