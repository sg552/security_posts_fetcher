ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

Rails.logger = Logger.new("log/get_xianzhi_blogs_using_proxy.log")

SLEEP = 60

URL = 'https://xz.aliyun.com'

def get_list_page_and_show_page url
  expiration_time = Time.now + 10
  proxy = Proxy.where('expiration_time > ?', expiration_time).all.shuffle.first
  Rails.logger.info "==== proxy ip: #{proxy.external_ip rescue ''}"
  command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{url}}
  Rails.logger.info "======-------------------==command_get_page: #{command_get_page}"
  result = `#{command_get_page}`
  Rails.logger.info "=== result #{result} command_get_page: #{command_get_page}"
  return result
end

def update_blog blog_url, html_content
  blog = Blog.where('blog_url = ?', blog_url).first
  Rails.logger.info html_content
  doc = Nokogiri::HTML(html_content)
  Rails.logger.info 'html_content 29 29 29 29 29 29      '
  to_get_author = doc.css('span[class="info-left"] a')
  author_url = "#{URL}#{to_get_author[0]}"
  Rails.logger.info author_url
  Rails.logger.info 'author_url'
  Rails.logger.info "==  author_url is #{author_url}"

  to_get_content = doc.css('div#topic_content') rescue ''
  Rails.logger.info "==  to_get_content is #{to_get_content}"
  # 获得博客内容的所有图片
  images = doc.css('div#topic_content img') rescue ''
  Rails.logger.info "=== images is #{images}"
  # 为了保存图片
  image_remote_and_local_hash = {}
  if images != ''
    images.to_ary.each do |image|
      image_src = image.attr("src")
      # 保存本地图片的名称
      image_name = image_src.to_s.gsub('/', '_').gsub(':', '')
      image_local = "###MY_IMAGE_SITE###/images/#{image_name}"
      image_remote_and_local_hash.store(image_src, image_local)
      `wget -cO - "#{image_src}" > "public/blog_images/#{image_name}"`
    end
  end
  Rails.logger.info "image_remote_and_local_hash #{image_remote_and_local_hash}"
  # 获得博客的内容
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

  username = doc.css('span[class="username cell"]').text
  Rails.logger.info "=== username is #{username}"

  to_get_created_at = doc.css('span[class="info-left"] span')
  temp_to_get_created_at = doc.css('span[class="info-left"] span')[5]
  # 获得浏览数
  views = to_get_created_at[4].text.split('数').last.to_i
  # 获得创建时间
  created_at = doc.css('span[class="info-left"] span')[2].text
  Rails.logger.info "======  to_get_created_at #{to_get_created_at}  views : #{views}  created_at : #{created_at}"

  to_get_category = doc.css('span[class="content-node"] a').each do |a|
    category_name  = a.text
    Rails.logger.info "======  category_name : #{category_name}"
    category = Category.where('name = ? and blog_id = ?', category, blog.id).first
    xianzhi_anquanjishu_column = ["安全技术", "众测渗透", "漏洞分析", "WEB安全", "二进制安全", "移动安全", "IoT安全", "企业安全", "区块链安全", "密码学", "CTF", "安全工具", "资源分享", "技术讨论"].to_s
    xianzhi_qingbao_column = ["情报", "先知情报"].to_s
    xianzhi_gonggao_column = ["社区公告"].to_s
    if xianzhi_anquanjishu_column.include?category_name
      special_column_local = SpecialColumn.where('name = ? and source_website = ?', "安全技术", 'xianzhi').first
    elsif xianzhi_qingbao_column.include?category_name
      special_column_local = SpecialColumn.where('name = ? and source_website = ?', "先知情报", 'xianzhi').first
    elsif xianzhi_gonggao_column.include?category_name
      special_column_local = SpecialColumn.where('name = ? and source_website = ?', "社区公告", 'xianzhi').first
    end
    if category.blank?
      Category.create name: category_name, blog_id: blog.id, special_column_id: special_column_local.id
    end
    Rails.logger.info "======  category: #{category.inspect}"
  end
  Rails.logger.info "======  to_get_category: #{to_get_category}"
  blog.update author: username, content: blog_content, created_at: created_at, source_website: 'xianzhi', views: views
end

def create_blogs html_content
  doc = Nokogiri::HTML(html_content)
  Rails.logger.info "============= doc is #{doc} "
  doc.css('p[class="topic-summary"] a').each do |title|
    blog_url = "#{URL}#{title["href"]}" rescue ''
    blog_title = title.text rescue ''
    Rails.logger.info "=============title: #{title} blog_title is #{blog_title}"
    if blog_title.present?
      Blog.create title: blog_title.strip, blog_url: blog_url, source_website: 'xianzhi'
      blog_html_doc = get_list_page_and_show_page blog_url
      Rails.logger.info "==== blog_html_doc: #{blog_html_doc} ==== blog_url #{blog_url}"
      update_blog blog_url, blog_html_doc
    end
  end
end


def run
  (ENV["FROM"].to_i .. ENV["TO"].to_i).each do |i|
    xianzhi_url = "#{ENV['URL']}?page=#{i}"
    result = get_list_page_and_show_page xianzhi_url
    Rails.logger.info "====env['to'] #{ENV["TO"]} env['from'] #{ENV["FROM"]}======== ENV['URL']#{ENV["URL"]} xianzhi_url: #{xianzhi_url}"
    create_blogs result
    Rails.logger.info "=== sleep #{SLEEP}"
    sleep SLEEP
  end
end

run()




