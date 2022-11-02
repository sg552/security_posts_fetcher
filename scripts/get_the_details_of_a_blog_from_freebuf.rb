ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'open-uri'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

@logger = Logger.new("#{Rails.root}/log/get_blogs_freebuf.log")
blogs = Blog.where('source_website = ?', 'freebuf').all
blogs.each do |blog|
  @logger.info "== blog.inspect #{blog.inspect}"
  headers = {
    'Host': 'www.freebuf.com',
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv: 106.0) Gecko/20100101 Firefox/106.0',
    'Accept': 'text/htmlapplication/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'zh-CNzh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
    'Accept-Encoding': 'gzip deflate, br',
    'Connection': 'keep-alive',
    'Cookie': 'Hm_lvt_cc53db168808048541c6735ce30421f5=1666947368,1667273727; hide_fb_detail_tooltips=true; wordpress_logged_in_a4d81fc826559e0a94da2a95b91820a7=linlin20221101%7C1667722001%7Cbc481b09197199ef1aaa1429efd4430e; token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJmcmVlYnVmLWFwaS5jb20iLCJhdWQiOiJ3d3cuZnJlZWJ1Zi5jb20iLCJqdGkiOiJjYmY3NDU1NmVkN2NlYmIyMDMxODg5NmExMDExMmQzYiIsImlhdCI6MTY2NzI5MDAwNC42OTE3NDMsIm5iZiI6MTY2NzI5MDAwNC42OTE3NDMsImV4cCI6MTY2NzcyMjAwNC42OTE3NDMsInVpZCI6IjM1NDEzMCIsInVzZXJuYW1lIjoibGlubGluMjAyMjExMDEifQ.L3uclrmrF0iEX-6k5FTGZgfHUtAguy4USCOeUcZi6o4; username=linlin20221101; user_pic=https://image.3001.net/images/index/wp-user-avatar-50x50.png; role=contributor; nickname=linlin20221101; phone=true; company_space=; userId=354130; Hm_lpvt_cc53db168808048541c6735ce30421f5=1667354441; new_prompt=1',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-User': '?1',
    'Sec-Fetch-Site': 'cross-site',
    'If-None-Match': '"11731-7q7wtZxjOOe6ntCPzZU2hvBe+uI"'
  }

  response = HTTParty.get blog.blog_url, :headers => headers
  @logger.info "===response.code, #{response.code} === response.headers is #{response.headers}"
  doc = Nokogiri::HTML(response.body)
  @logger.info "=== doc is #{doc} doc.class: #{doc.class}"


  to_get_content = doc.css('div[class="artical-body"]') rescue ''
  @logger.info "==  to_get_content is #{to_get_content}"
  #获得博客内容的所有图片
  images = doc.css('div[class="artical-body"] img') rescue ''
  @logger.info "=== images is #{images}"
  #为了保存图片
  image_remote_and_local_hash = {}
  if images != ''
    images.to_ary.each do |image|
      image_src = image.attr("src")
      #保存本地图片的名称
      image_name = image_src.to_s.gsub('/', '_').gsub(':', '')
      image_local = "###MY_IMAGE_SITE###/images/#{image_name}"
      image_remote_and_local_hash.store(image_src, image_local)
      `wget -cO - "#{image_src}" > "public/blog_images/#{image_name}"`
    end
  end
  @logger.info "image_remote_and_local_hash #{image_remote_and_local_hash}"
  #获得博客的内容
  blog_content = to_get_content.to_s
  @logger.info "=== before replace image_url blog_content is #{blog_content}"
  image_remote_and_local_hash.map {|key, value|
    @logger.info "==== key #{key} value: #{value}"
    blog_content = blog_content.to_s.gsub("#{key.to_s}", "#{value.to_s}")
    @logger.info "=== after replace image_url blog_content is #{blog_content}"
  }
  @logger.info "=== end map content is #{blog_content}"

  blog.update content: blog_content

  @logger.info "===start 5  === blog: #{blog.inspect}"
  sleep 5
  @logger.info '==end 5'
end
