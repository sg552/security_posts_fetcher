ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

Rails.logger = Logger.new("log/get_xianzhi_blogs_regular.log")

SLEEP = 60
URL = 'https://xz.aliyun.com'
TIMEOUT = 35
NUMBER = 5

def retry_to_get_list_page url
  n = 0
  begin
    proxy = Proxy.where('expiration_time > ?', Time.now).all.shuffle.first
    Rails.logger.info "==== step 1.3 retry_to_get_list_page url: #{url} The proxy IP for accessing the Xianzhi community is: #{proxy.external_ip rescue ''}"
    command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{url}}
    result = `#{command_get_page}`
    Rails.logger.info "===  step 1.3.1 retry_to_get_list_page url: #{url}The command to get the Xianzhi community list page is: #{command_get_page} The return result is #{result}"
    doc = Nokogiri::HTML(result)
    Rails.logger.info "===== step1.4  url: #{url} The html of the Xianzhi community list page is #{doc} "
    list_page_titles = doc.css('p[class="topic-summary"] a')
  rescue => error
    Rails.logger.error "=== setp1.5 url: #{url} to get the html of the Xianzhi community list page error : #{error}"
    n = n + 1
    retry if n < 3
  end
  return list_page_titles
end

def create_proxy
  command_get_token = %Q{curl -d "user=bigbanana666&password=bigbanana888" https://dvapi.doveproxy.net/cmapi.php?rq=login}
  get_token = `#{command_get_token}`
  proxy_token = JSON.parse(get_token)['data']['token']
  Rails.logger.info "====step 1 create_proxy, command_get_token #{command_get_token} ============proxy_token #{proxy_token}"
  city = ['in', 'id', 'ru', 'bd', 'za'].shuffle.first
  command_get_ip = %Q{curl -ipv4 -d "user=bigbanana666&token=#{proxy_token}&geo=#{city}&timeout=#{TIMEOUT}&num=#{NUMBER}" https://dvapi.doveproxy.net/cmapi.php?rq=distribute}
  puts "command_get_ip #{command_get_ip}"
  Rails.logger.info "========== step 1.1 command_get_ip #{command_get_ip}"
  get_ip = `#{command_get_ip}`
  temp_ip = get_ip.to_s.split("\r\n\r\n").last
  datas = JSON.parse(temp_ip)['data'] rescue ''
  Rails.logger.info "==== step 1.2 proxy datas #{datas}"
  if datas.present?
    datas.each do |data|
      Proxy.create ip: data['ip'], port: data['port'], external_ip: data['d_ip'], expiration_time: (Time.now + TIMEOUT * 60) if data.present?
    end
  end
  Proxy.where('expiration_time < ?', Time.now).delete_all
end

def run
  loop do
    create_proxy()
    url = ENV["URL"]
    proxy = Proxy.where('expiration_time > ?', Time.now).all.shuffle.first
    Rails.logger.info "==== step 2.1 url: #{url} proxy ip: #{proxy.external_ip rescue ''}"
    command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{url}}
    Rails.logger.info "==== command_get_page #{command_get_page}"
    result = `#{command_get_page}`
    Rails.logger.info "=== step 2.2 url: #{url}  result #{result} command_get_page: #{command_get_page}"
    doc = Nokogiri::HTML(result)
    Rails.logger.info "====== step 2.3 url: #{url}  list_page doc is #{doc}"
    list_page_titles = doc.css('p[class="topic-summary"] a') rescue ''
    list_page_titles = retry_to_get_list_page url if list_page_titles.blank?
    doc.css('p[class="topic-summary"] a').each do |title|
      blog_url = "#{URL}#{title["href"]}" rescue ''
      blog_title = title.text rescue ''
      blog_local = Blog.where('blog_url = ?', blog_url).first
      Rails.logger.info "===== setp 3 url #{url} blog_url: #{blog_url} blog_local: #{blog_local.inspect} ========title: #{title} blog_title is #{blog_title}"
      if blog_url.present? && blog_local.blank?
        Blog.create blog_url: blog_url, title: blog_title.strip, source_website: 'xianzhi'
        sleep SLEEP
      end
    end
    Rails.logger.info "=== sleep 24 * 3600"
    sleep 24 * 3600
  end
end

run()



