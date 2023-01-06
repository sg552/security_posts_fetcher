ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

Rails.logger = Logger.new("log/get_kanxue_blogs_using_playwright.log")

file_name = 'tests/kanxue.spec.js'
text = File.read(file_name)
new_contents = text.gsub(/page_start/, "#{ENV['PAGE_START']}").gsub(/page_end/, "#{ENV['PAGE_END']}")
Rails.logger.info new_contents
new_file = "tests/kanxue_#{ENV['PAGE_START']}_#{ENV['PAGE_END']}.spec.js"
File.open(new_file, "w+") do |f|
  f.write(new_contents)
end

command = %Q{npx playwright test #{new_file} --debug}
result = `#{command}`
Rails.logger.info "========== result: #{result}"
doc = Nokogiri::HTML(result)
Rails.logger.info "=== doc is #{doc}"
doc.css('div[class="media p-4 home_article bg-white"]').each do |title|
  Rails.logger.info "=== title is #{title}"
  temp_image_url = title.css('div[class="mr-4 article-img"]').to_s.split('url(').last.split(')').first
  image_url = "https:#{temp_image_url}"
  blog_title = title.css('h4').text.strip
  blog_url = title.css('div[class="media-body position-relative"] a')[0]["href"]
  Rails.logger.info "=== image_url: #{image_url} blog_title #{blog_title} blog_url :#{blog_url}"

  blog = Blog.where('blog_url = ?', blog_url).first
  if blog.blank?
    Blog.create title: blog_title, blog_url: blog_url, image_url: image_url, source_website: 'kanxue'
  end

end
Rails.logger.info "== blog.count #{Blog.count}"

