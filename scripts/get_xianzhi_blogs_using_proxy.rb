ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

Rails.logger = Logger.new("log/get_xianzhi_blogs_using_proxy#{ENV['FROM']}_#{ENV['TO']}.log")

SLEEP = 60
URL = 'https://xz.aliyun.com'
TIMEOUT = 10
NUMBER = 10


Rails.logger.info "====env['to'] #{ENV["TO"]} env['from'] #{ENV["FROM"]}======== ENV['URL']#{ENV["URL"]}"

def retry_to_get_list_page xianzhi_url
  n = 0
  begin
    proxy = Proxy.where('expiration_time > ?', Time.now).all.shuffle.first
    Rails.logger.info "==== step 1.3 retry_to_get_list_page url: #{xianzhi_url} The proxy IP for accessing the Xianzhi community is: #{proxy.external_ip rescue ''}"
    command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{xianzhi_url}}
    result = `#{command_get_page}`
    Rails.logger.info "===  step 1.3.1 retry_to_get_list_page url: #{xianzhi_url}The command to get the Xianzhi community list page is: #{command_get_page} The return result is #{result}"
    doc = Nokogiri::HTML(result)
    Rails.logger.info "===== step1.4  url: #{xianzhi_url} The html of the Xianzhi community list page is #{doc} "
    list_page_titles = doc.css('p[class="topic-summary"] a')
  rescue => error
    Rails.logger.error "=== setp1.5 url: #{xianzhi_url} to get the html of the Xianzhi community list page error : #{error}"
    n = n + 1
    retry if n < 3
  end
  return list_page_titles
end

def run
  (ENV["FROM"].to_i .. ENV["TO"].to_i).each do |i|
    xianzhi_url = "#{ENV['URL']}?page=#{i}"
    proxy = Proxy.where('expiration_time > ?', Time.now).all.shuffle.first
    Rails.logger.info "====  xianzhi_url #{xianzhi_url} step1 proxy ip: #{proxy.external_ip rescue ''}"
    command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{xianzhi_url}}
    result = `#{command_get_page}`
    Rails.logger.info "=== xianzhi_url #{xianzhi_url} step1.1  result #{result} command_get_page: #{command_get_page}"
    doc = Nokogiri::HTML(result)
    Rails.logger.info "======xianzhi_url #{xianzhi_url} step1.2  list_page doc is #{doc}"
    list_page_titles = doc.css('p[class="topic-summary"] a') rescue ''
    list_page_titles = retry_to_get_list_page xianzhi_url if list_page_titles.blank?
    doc.css('p[class="topic-summary"] a').each do |title|
      blog_url = "#{URL}#{title["href"]}" rescue ''
      blog_title = title.text rescue ''
      blog_local = Blog.where('blog_url = ?', blog_url).first
      Rails.logger.info "===== xianzhi_url #{xianzhi_url} step2  blog_url: #{blog_url} blog_local: #{blog_local.inspect} ========title: #{title} blog_title is #{blog_title}"
      if blog_url.present? && blog_local.blank?
        Blog.create blog_url: blog_url, title: blog_title.strip, source_website: 'xianzhi'
        sleep SLEEP
      end
    end
    sleep SLEEP
  end
  Rails.logger.info "====after created ===#{ENV['FROM']}_#{ENV['TO']}======== end"
end

run()



