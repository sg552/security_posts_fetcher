ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

Rails.logger = Logger.new("log/get_xianzhi_blogs_using_proxy.log")

SLEEP = 20

def get_list_page page_name, xianzhi_url
  expiration_time = Time.now + 10
  proxy = Proxy.where('expiration_time > ?', expiration_time).all.shuffle.first
  Rails.logger.info "==== proxy ip: #{proxy.external_ip rescue ''}"
  page_html_file_name = "public/xianzhi_blogs/#{page_name}.html"
  command_get_page = %Q{curl -s -o #{page_html_file_name} --socks5 #{proxy.ip}:#{proxy.port} #{xianzhi_url}}
  result = `#{command_get_page}`
  Rails.logger.info "=== result #{result} command_get_page#{command_get_page}"
  return page_html_file_name
end

def create_blogs file
  #doc = Nokogiri::HTML("public/xianzhi_blogs/page#{i}.html")
  Rails.logger.info "==== #{file}"
  doc = Nokogiri::HTML("#{file}")
  Rails.logger.info "=== doc is #{doc} file #{file}"
  doc.css('p[class="topic-summary"] a').each do |title|
    Rails.logger.info "=== title is #{title}"
    blog_url = "#{xz_url}#{title["href"]}" rescue ''
    Rails.logger.info "== blog_url is #{blog_url}"

    blog_title = title.text rescue ''
    Rails.logger.info "=== blog_title is #{blog_title}"
    if blog_title != ''
      Blog.create title: blog_title.strip, blog_url: blog_url, source_website: 'xianzhi'
    end
  end
end


def run
  (ENV["FROM"].to_i .. ENV["TO"].to_i).each do |i|
    xianzhi_url = "#{ENV['URL']}?page=#{i}"
    page_html_file_name = get_list_page "#{ENV['PAGE_TYPE']}#{i}", xianzhi_url
    create_blogs page_html_file_name
    Rails.logger.info "=== sleep #{SLEEP}"
    sleep SLEEP
  end
end

run()




