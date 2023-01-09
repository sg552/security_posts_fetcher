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
    Rails.logger.info "==== proxy ip: #{proxy.external_ip rescue ''}"
    command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{xianzhi_url}}
    result = `#{command_get_page}`
    Rails.logger.info "=== result #{result} command_get_page: #{command_get_page}"
    doc = Nokogiri::HTML(result)
    Rails.logger.info "============= doc is #{doc} "
    list_page_titles = doc.css('p[class="topic-summary"] a')
  rescue => error
    Rails.logger.info "=== error #{error}"
    n = n + 1
    retry if n < 3
  end
  return list_page_titles
end

def run
  (ENV["FROM"].to_i .. ENV["TO"].to_i).each do |i|
    xianzhi_url = "#{ENV['URL']}?page=#{i}"
    proxy = Proxy.where('expiration_time > ?', Time.now).all.shuffle.first
    Rails.logger.info "==== proxy ip: #{proxy.external_ip rescue ''}"
    command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{xianzhi_url}}
    result = `#{command_get_page}`
    Rails.logger.info "=== result #{result} command_get_page: #{command_get_page}"
    doc = Nokogiri::HTML(result)
    Rails.logger.info "============= doc is #{doc}"
    list_page_titles = doc.css('p[class="topic-summary"] a') rescue ''
    list_page_titles = retry_to_get_list_page xianzhi_url if list_page_titles.blank?
    Rails.logger.info "============= list_page is present"
    doc.css('p[class="topic-summary"] a').each do |title|
      blog_url = "#{URL}#{title["href"]}" rescue ''
      blog_title = title.text rescue ''
      blog_local = Blog.where('blog_url = ?', blog_url).first
      Rails.logger.info "=====blog_url: #{blog_url} blog_local: #{blog_local.inspect}========title: #{title} blog_title is #{blog_title}"
      if blog_url.present? && blog_local.blank?
        blog = Blog.create blog_url: blog_url, title: blog_title.strip, source_website: 'xianzhi'
      elsif blog_local.present? && blog_local.content.blank?
        UpdateKanxueBlogUsingProxyJob.perform_later blog: blog_local
      end
      sleep SLEEP
    end
  end
  Rails.logger.info "====after created ===#{ENV['FROM']}_#{ENV['TO']}======== end"
end

run()



