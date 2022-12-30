ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

Rails.logger = Logger.new("log/get_xianzhi_blogs_using_proxy.log")

SLEEP = 30
URL = 'https://xz.aliyun.com'
TIMEOUT = 3
NUMBER = 10

def get_proxy_token
  command_get_token = %Q{curl -d "user=bigbanana666&password=bigbanana888" https://dvapi.doveproxy.net/cmapi.php?rq=login}
  get_token = `#{command_get_token}`
  proxy_token = JSON.parse(get_token)['data']['token']
  Rails.logger.info "=========command_get_token #{command_get_token} ============proxy_token #{proxy_token}"
  return proxy_token
end

def get_ip_and_port
  proxy_token = get_proxy_token
  puts "proxy_token#{proxy_token}"
  city = ['in', 'id', 'ru', 'bd', 'za'].shuffle.first
  command_get_ip = %Q{curl -ipv4 -d "user=bigbanana666&token=#{proxy_token}&geo=#{city}&num=#{NUMBER}&timeout=#{TIMEOUT}" https://dvapi.doveproxy.net/cmapi.php?rq=distribute}
  puts "command_get_ip #{command_get_ip}"
  Rails.logger.info "========== command_get_ip #{command_get_ip}"
  get_ip = `#{command_get_ip}`
  temp_ip = get_ip.to_s.split("\r\n\r\n").last
  data = JSON.parse(temp_ip)['data'] rescue ''
  Rails.logger.info "==== proxy datas #{data}"
  return data
end

def create_proxy
  loop do
    datas = get_ip_and_port
    if datas.present?
      datas.each do |data|
        Proxy.create ip: data['ip'], port: data['port'], external_ip: data['d_ip'], expiration_time: (Time.now + TIMEOUT * 60) if data.present?
      end
    end
    Proxy.where('expiration_time < ?', Time.now).delete_all
    sleep TIMEOUT * 60
  end
end

def save_images images
  image_remote_and_local_hash = {}
  images.to_ary.each do |image|
    image_src = image.attr("src")
    # 保存本地图片的名称
    image_name = image_src.to_s.gsub('/', '_').gsub(':', '')
    image_local = "###MY_IMAGE_SITE###/images/#{image_name}"
    image_remote_and_local_hash.store(image_src, image_local)
    proxy = Proxy.where('expiration_time > ?', Time.now).all.shuffle.first
    Rails.logger.info "==== in save_images proxy ip: #{proxy.external_ip rescue ''}"
    command_get_image = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{image_src} --output #{image_local}}
    Rails.logger.info "======  command_get_image: #{command_get_image}"
    result = `#{command_get_image}`
    Rails.logger.info "=== result #{result} command_get_image: #{command_get_image}"
  end
  return image_remote_and_local_hash
end

def create_category doc, blog_url
  blog = Blog.where('blog_url = ?', blog_url).first
  if blog.present?
    to_get_category = doc.css('span[class="content-node"] a').each do |a|
      category_name  = a.text
      Rails.logger.info "======  category_name : #{category_name}"
      category = Category.where('name = ? and blog_id = ?', category, blog.id).first
      xianzhi_anquanjishu_column = ["安全技术", "众测渗透", "漏洞分析", "WEB安全", "二进制安全", "移动安全", "IoT安全", "企业安全", "区块链安全", "密码学", "CTF", "安全工具", "资源分享", "技术讨论"].to_s
      xianzhi_qingbao_column = ["情报", "先知情报"].to_s
      xianzhi_gonggao_column = ["社区公告"].to_s
      special_column_local = ''
      if xianzhi_anquanjishu_column.include? category_name
        special_column_local = SpecialColumn.where('name = ? and source_website = ?', "安全技术", 'xianzhi').first
      elsif xianzhi_qingbao_column.include? category_name
        special_column_local = SpecialColumn.where('name = ? and source_website = ?', "先知情报", 'xianzhi').first
      elsif xianzhi_gonggao_column.include? category_name
        special_column_local = SpecialColumn.where('name = ? and source_website = ?', "社区公告", 'xianzhi').first
      end
      if category.blank?
        Category.create name: category_name, blog_id: blog.id, special_column_id: special_column_local.id
      end
      Rails.logger.info "======  category: #{category.inspect} to_get_category: #{to_get_category}"
    end
  end
end


def use_proxy
  proxy = Proxy.where('expiration_time > ?', Time.now).all.shuffle.first
  if proxy.blank?
    create_proxy
    proxy = Proxy.where('expiration_time > ?', Time.now).all.shuffle.first
  end
  return proxy
end

Rails.logger.info "====env['to'] #{ENV["TO"]} env['from'] #{ENV["FROM"]}======== ENV['URL']#{ENV["URL"]}"
def run
  (ENV["FROM"].to_i .. ENV["TO"].to_i).each do |i|
    xianzhi_url = "#{ENV['URL']}?page=#{i}"
    #result = get_list_page_and_show_page xianzhi_url
    # 使用一個ip 获得 list show image
    proxy = use_proxy
    Rails.logger.info "==== proxy ip: #{proxy.external_ip rescue ''}"
    command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{xianzhi_url}}
    result = `#{command_get_page}`
    Rails.logger.info "=== result #{result} command_get_page: #{command_get_page}"
    doc = Nokogiri::HTML(result)
    Rails.logger.info "============= doc is #{doc} "
    doc.css('p[class="topic-summary"] a').each do |title|
      blog_url = "#{URL}#{title["href"]}" rescue ''
      blog_title = title.text rescue ''
      Rails.logger.info "=============title: #{title} blog_title is #{blog_title}"
      blog_local = Blog.where('blog_url = ?', blog_url).first
      if blog_url.present? && blog_local.blank?
        command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{blog_url}}
        Rails.logger.info "======-------------------==command_get_page: #{command_get_page}"
        blog_html_doc = `#{command_get_page}`
        blog_show_doc = Nokogiri::HTML(blog_html_doc)
        to_get_author = blog_show_doc.css('span[class="info-left"] a')
        author_url = "#{URL}#{to_get_author[0]}"
        to_get_content = blog_show_doc.css('div#topic_content') rescue ''
        Rails.logger.info "==  to_get_content is #{to_get_content}  author_url #{author_url}"
        # 获得博客内容的所有图片
        images = blog_show_doc.css('div#topic_content img') rescue ''
        Rails.logger.info "=== images is #{images}"
        # 为了保存图片
        #image_remote_and_local_hash = save_images images if images.present?
        image_remote_and_local_hash = {}
        images.to_ary.each do |image|
          image_src = image.attr("src")
          # 保存本地图片的名称
          image_name = image_src.to_s.gsub('/', '_').gsub(':', '')
          image_local = "###MY_IMAGE_SITE###/images/#{image_name}"
          image_remote_and_local_hash.store(image_src, image_local)
          #`wget -cO - "#{image_src}" > "public/blog_images/#{image_name}"`
          Rails.logger.info "==== in save_images proxy ip: #{proxy.external_ip rescue ''}"
          command_get_image = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{image_src} --output #{image_local}}
          Rails.logger.info "======  command_get_image: #{command_get_image}"
          result = `#{command_get_image}`
          Rails.logger.info "=== result #{result} command_get_image: #{command_get_image}"
        end
        # 获得博客的内容
        if to_get_content.present?
          blog_content = to_get_content.to_s
          Rails.logger.info "=== before replace image_url blog_content is #{blog_content}"
          image_remote_and_local_hash.map {|key, value|
            if key.to_s.include?('http')
              Rails.logger.info "==== key #{key} value: #{value}"
              blog_content = blog_content.to_s.gsub("#{key.to_s}", "#{value.to_s}")
            end
            Rails.logger.info "=== after replace image_url blog_content is #{blog_content}"
          }
          Rails.logger.info "=== end map content is #{blog_content}"
        end

        username = blog_show_doc.css('span[class="username cell"]').text
        Rails.logger.info "=== username is #{username}"
        to_get_created_at = blog_show_doc.css('span[class="info-left"] span')
        temp_to_get_created_at = blog_show_doc.css('span[class="info-left"] span')[5]
        # 获得浏览数
        views = to_get_created_at[4].text.split('数').last.to_i
        # 获得创建时间
        created_at = blog_show_doc.css('span[class="info-left"] span')[2].text
        Rails.logger.info "======  to_get_created_at #{to_get_created_at}  views : #{views}  created_at : #{created_at}"
        # create blog
        Blog.create title: blog_title.strip, blog_url: blog_url, source_website: 'xianzhi', author: username, content: blog_content, created_at: created_at, views: views
        create_category blog_show_doc, blog_url
        sleep SLEEP
      end
      sleep SLEEP
    end

    Rails.logger.info "=== i: #{i} sleep #{SLEEP}"
    sleep SLEEP
  end
end


run()


