ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

i = 1
loop do
  freebuf_url = "https://www.freebuf.com/fapi/frontend/home/article?page=#{i}&limit=20&type=1&day=7&category=%E7%B2%BE%E9%80%89"
  @logger = Logger.new("#{Rails.root}/log/get_blogs_from_freebuf.log")
  response = HTTParty.get freebuf_url
  @logger.info response.body
  body = JSON.parse(response.body)
  temp_blogs = body["data"]["list"]
  @logger.info temp_blogs
  temp_blogs.each do |temp_blog|
    url = "https://www.freebuf.com/articles/#{temp_blog["ID"]}.html"
    puts url
    blog_local = Blog.where('blog_url = ?', url).first
    if blog_local.blank?
      title = temp_blog['post_title']
      created_at = temp_blog['post_date']
      author_url = "https://www.freebuf.com/author/#{temp_blog['post_author']}"
      remote_image_url = temp_blog['column_post_picture']
      image_name = remote_image_url.gsub('/', '_').gsub(':', '')
      `wget -cO - "#{remote_image_url}" > "public/blog_images/#{image_name}"`
      image_url = "###MY_IMAGE_SITE###/images/#{image_name}"
      special_column_name = temp_blog['category']
      author = temp_blog['username']
      views = temp_blog['read_count'].to_i
      @logger.info "=== url: #{url} title: #{title} created_at: #{created_at} author_url: #{author_url} image_url: #{image_url} category: #{category} author:#{author} views:#{views}"
      blog = Blog.create blog_url: url, author: author, views: views, title: title, created_at: created_at, image_url: image_url, source_website: 'freebuf', author_url: author_url
      special_column_local = SpecialColumn.where('name = ? and source_website = ?', special_column_name, 'freebuf').first
      if special_column_local.blank?
        special_column_local = SpecialColumn.create name: special_column_name, source_website: 'freebuf'
        @logger.info "===special_column_name:#{special_column_name} special_column_local: #{special_column_local.inspect}"
      end
      @logger.info "=== SpecialColumn.all.size #{SpecialColumn.all.size}"
    end
  end
  i = i + 1
  @logger.info "=== i: #{i}"
  if i >10
    break
  end
end
