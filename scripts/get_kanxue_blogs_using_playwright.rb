ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

Rails.logger = Logger.new("log/get_kanxue_blogs_using_playwright.log")

def generate_a_script_to_crawl_the_list_page_of_the_kanxue
  file_name = 'tests/kanxue.spec.js'
  text = File.read(file_name)
  new_contents = text.gsub(/page_start/, "#{ENV['PAGE_START']}").gsub(/page_end/, "#{ENV['PAGE_END']}")
  Rails.logger.info new_contents
  new_file = "tests/kanxue_#{ENV['PAGE_START']}_#{ENV['PAGE_END']}.spec.js"
  File.open(new_file, "w+") do |f|
    f.write(new_contents)
  end
  return new_file
end

def create_blogs
  new_file = generate_a_script_to_crawl_the_list_page_of_the_kanxue()
  command = %Q{npx playwright test #{new_file}}
  result = `#{command}`
  doc = Nokogiri::HTML(result)
  Rails.logger.info "=== the snow community list page is #{doc}"
  doc.css('div[class="media p-4 home_article bg-white"]').each do |title|
    Rails.logger.info "=== one of the blogs on the list page of the snow community is #{title}"
    temp_image_url = title.css('div[class="mr-4 article-img"]').to_s.split('url(').last.split(')').first
    image_url = "https:#{temp_image_url}"
    blog_title = title.css('h4').text.strip
    blog_url = title.css('div[class="media-body position-relative"] a')[0]["href"]
    Rails.logger.info "=== the cover of the kanxue community blog : #{image_url} blog_url :#{blog_url} blog_title: #{blog_title}"
    views = doc.css('div[class="col text-right text-truncate px-0"] span')[2].text.to_i rescue ''

    created_at = doc.css('div[class="col text-right text-truncate px-0"] span')[1].text rescue ''
    if created_at.include?('天') && created_at.present?
      temp_created_at =  created_at.split('天').first.to_i
      Rails.logger.info "=== temp_created_at #{temp_created_at}"
      created_at = Time.now - temp_created_at * 3600 * 24
      Rails.logger.info "=== created_at#{created_at}"
    elsif created_at.include?('小时') && created_at.present?
      temp_created_at =  created_at.split('小时').first.to_i
      Rails.logger.info "=== temp_created_at #{temp_created_at}"
      created_at = Time.now - temp_created_at * 3600
      Rails.logger.info "=== created_at#{created_at}"
    end

    Rails.logger.info "==== create_at: #{created_at} views: #{views}"
    blog = Blog.where('blog_url = ?', blog_url).first
    if blog.blank?
      Blog.create title: blog_title, blog_url: blog_url, image_url: image_url, source_website: 'kanxue', created_at: created_at, views: views
      sleep 5
    end
  end
end

create_blogs()




