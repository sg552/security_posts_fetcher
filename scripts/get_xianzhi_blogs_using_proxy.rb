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
  city = ['in', 'hk', 'tw', 'bd', 'za'].shuffle.first
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
  datas = get_ip_and_port
  if datas.present?
    datas.each do |data|
      Proxy.create ip: data['ip'], port: data['port'], external_ip: data['d_ip'], expiration_time: (Time.now + TIMEOUT * 60) if data.present?
    end
  end
  Proxy.where('expiration_time < ?', Time.now).delete_all
end

def retry_to_save_image image_src, image_name
  proxy = use_proxy
  command_get_image = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{image_src} --output public/blog_images/#{image_name}}
end

def retry_three_to_save_image image_src, image_name
  begin
    retry_to_save_image image_src, image_name
  rescue
    begin
      retry_to_save_image image_src, image_name
    rescue
      begin
        retry_to_save_image image_src, image_name
      rescue
        Rails.logger.info "============ curl image #{image_src} to loacl #{image_name} error"
      end
    end
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
    proxy = use_proxy
    Rails.logger.info "==== in save_images proxy ip: #{proxy.external_ip rescue ''}"
    begin
      command_get_image = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{image_src} --output public/blog_images/#{image_name}}
    rescue
      retry_three_to_save_image image_src, image_name
    end
    Rails.logger.info "======  command_get_image: #{command_get_image}"
    result = `#{command_get_image}`
    Rails.logger.info "=== result #{result} command_get_image: #{command_get_image}"
  end
  return image_remote_and_local_hash
end

def create_category blog_id, category_name
  if category_name.present?
    special_column_local = ''
    if category_name.include?("社区")
      special_column_local = SpecialColumn.where('name = ? and source_website = ?', "社区公告", 'xianzhi').first
    elsif category_name.include?('技术文章')
      special_column_local = SpecialColumn.where('name = ? and source_website = ?', "技术文章", 'xianzhi').first
    elsif category_name.include?('翻译文章')
      special_column_local = SpecialColumn.where('name = ? and source_website = ?', "翻译文章", 'xianzhi').first
    end
    Rails.logger.info "==== special_column_local id : #{special_column_local.id rescue ''}"
    category = Category.where('name = ? and blog_id = ?', category_name, blog_id).first
    Rails.logger.info "======  category: #{category.inspect}"
    if category.blank?
      Category.create name: category_name, blog_id: blog_id, special_column_id: special_column_local.id
    end
    Rails.logger.info "======  category_name : #{category_name} special_column_local name: #{special_column_local.name rescue ''}"
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

def retry_to_get_blog_show_page blog_url
  proxy = use_proxy
  command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{blog_url}}
  Rails.logger.info "======-------------------==command_get_page: #{command_get_page}"
  blog_html_doc = `#{command_get_page}`
  blog_show_doc = Nokogiri::HTML(blog_html_doc)
  to_get_content = blog_show_doc.css('div#topic_content') rescue ''
  return blog_show_doc
end

def retry_three_to_get_blog_show_page blog_url
  begin
   blog_show_doc = retry_to_get_blog_show_page blog_url
  rescue
    begin
      blog_show_doc = retry_to_get_blog_show_page blog_url
    rescue
      begin
        blog_html_doc = retry_to_get_blog_show_page blog_url
     rescue
       Rails.logger.info "======== get blog_show_doc error"
     end
   end
  end
end

def update_blog blog_url, proxy_id
  blog = Blog.where('blog_url = ?', blog_url).first
  #proxy = use_proxy
  proxy = Proxy.where('id = ?', proxy_id).first
  if blog.blog_url.present? && blog.content.blank?
    begin
      command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{blog.blog_url}}
    rescue
      proxy = use_proxy
      command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{blog.blog_url}}
    end
    Rails.logger.info "======-------------------==command_get_page: #{command_get_page}"
    blog_html_doc = `#{command_get_page}`
    blog_show_doc = Nokogiri::HTML(blog_html_doc)
    to_get_content = blog_show_doc.css('div#topic_content') rescue ''
    blog_show_doc = retry_three_to_get_blog_show_page blog_url if to_get_content.blank?
    to_get_content = blog_show_doc.css('div#topic_content') rescue ''
    to_get_author = blog_show_doc.css('span[class="info-left"] a')
    author_url = "#{URL}#{to_get_author[0]}"
    Rails.logger.info "==  to_get_content is #{to_get_content}  author_url #{author_url}"
    # 获得博客内容的所有图片
    images = blog_show_doc.css('div#topic_content img') rescue ''
    Rails.logger.info "=== images is #{images}"
    # 为了保存图片
    image_remote_and_local_hash = save_images images if images.present?
    Rails.logger.info "====== image_remote_and_local_hash #{image_remote_and_local_hash}"
    # 获得博客的内容
    if to_get_content.present? && image_remote_and_local_hash.present?
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
    elsif to_get_content.present?
      blog_content = to_get_content.to_s
    end

    username = blog_show_doc.css('span[class="username cell"]').text rescue ''
    Rails.logger.info "=== username is #{username}"
    to_get_created_at = blog_show_doc.css('span[class="info-left"] span')
    temp_to_get_created_at = blog_show_doc.css('span[class="info-left"] span')[5] rescue ''
    # 获得浏览数
    views = to_get_created_at[4].text.split('数').last.to_i rescue ''
    # 获得创建时间
    created_at = blog_show_doc.css('span[class="info-left"] span')[2].text rescue ''
    Rails.logger.info "======  to_get_created_at #{to_get_created_at}  views : #{views}  created_at : #{created_at}"
    # create blog
    if created_at.blank?
      blog.update source_website: 'xianzhi', author: username, content: blog_content, views: views
    else
      blog.update source_website: 'xianzhi', author: username, content: blog_content, created_at: created_at, views: views
    end
    category_name = blog_show_doc.css('span[class="content-node"] a').text rescue ''
    Rails.logger.info "========= category_name:#{category_name}"
    create_category blog.id, category_name
    sleep SLEEP
  end
end

def retry_to_get_list_page xianzhi_url
  proxy = use_proxy
  Rails.logger.info "==== proxy ip: #{proxy.external_ip rescue ''}"
  command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{xianzhi_url}}
  result = `#{command_get_page}`
  Rails.logger.info "=== result #{result} command_get_page: #{command_get_page}"
  doc = Nokogiri::HTML(result)
  Rails.logger.info "============= doc is #{doc} "
  list_page_titles = doc.css('p[class="topic-summary"] a')
  return list_page_titles
end

def retry_three_to_get_list_page xianzhi_url
  begin
    list_page_titles =retry_to_get_list_page xianzhi_url
  rescue
    begin
      list_page_titles =retry_to_get_list_page xianzhi_url
      begin
       list_page_titles = retry_to_get_list_page xianzhi_url
      rescue
        Rails.logger.info "==== get list page error"
      end
    end
  end
  return list_page_titles
end

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
    list_page_titles = doc.css('p[class="topic-summary"] a') rescue ''
    list_page_titles = retry_three_to_get_list_page xianzhi_url if list_page_titles.blank?
    Rails.logger.info "============= list_page is present"
    doc.css('p[class="topic-summary"] a').each do |title|
      blog_url = "#{URL}#{title["href"]}" rescue ''
      blog_title = title.text rescue ''
      blog_local = Blog.where('blog_url = ?', blog_url).first
      Rails.logger.info "=====blog_url: #{blog_url} blog_local: #{blog_local.inspect}========title: #{title} blog_title is #{blog_title}"
      if blog_url.present? && blog_local.blank?
        Blog.create blog_url: blog_url, title: blog_title.strip, source_website: 'xianzhi'
        Rails.logger.info "========= after create"
        update_blog blog_url, proxy.id
      elsif blog_local.present? && blog_local.content.blank?
        update_blog blog_url, proxy.id
      end
    end
  end
  Rails.logger.info "====after created ===#{ENV['FROM']}_#{ENV['TO']}======== end"
end


run()


