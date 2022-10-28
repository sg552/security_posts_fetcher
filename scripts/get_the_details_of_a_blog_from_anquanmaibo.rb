ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'open-uri'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

blogs = Blog.all
blogs.each do |blog|
  if blog.content.blank? && blog.blog_url.include?('secpulse')
    puts "== blog.inspect #{blog.inspect}"
    headers = {
      'Host': 'www.secpulse.com',
      'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Gecko/20100101 Firefox/106.0',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Cookie': 'Hm_lvt_7f4cc5524dcb1aec487b4266c18bae48=1666943504; Hm_lpvt_7f4cc5524dcb1aec487b4266c18bae48=1666948647',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'cross-site'
    }

    response = HTTParty.get blog.blog_url, :headers => headers
    puts "===response.code, #{response.code} === response.headers is #{response.headers}"
    doc = Nokogiri::HTML(response.body)
    puts "=== doc is #{doc} doc.class#{doc.class}"

    to_get_titile = doc.css('h1').text rescue ''
    puts "==== to_get_titile: #{to_get_titile}"
    to_get_author = doc.css('span[class="writer"] a')
    author_url = "#{to_get_author[0]["href"]}"
    author = "#{to_get_author[0].text}"
    puts "==== to_get_author : #{to_get_author}==== author_url: #{author_url}==== author: #{author}"

    to_get_content = doc.css('div[class="left-9-code"]') rescue ''
    puts "==  to_get_content is #{to_get_content}"
    images = to_get_content.css('img') rescue ''
    puts "=== images is #{images}"
    blog_content = ''
    remote_uploads_url = "https://secpulseoss.oss-cn-shanghai.aliyuncs.com/wp-content/uploads/"
    if images != ''
      images.to_ary.each do |image|
        puts "=== image is #{image}"
        #https://secpulseoss.oss-cn-shanghai.aliyuncs.com/wp-content/uploads/1970/01/beepress-image-189910-1666849072.png
        image_src = image.attr("src") rescue ''
        puts "--- image_src is #{image_src} "
        temp_image_name = image_src.sub("#{remote_uploads_url}", '') rescue ''
        image_name = temp_image_name.gsub('/', '_')
        puts "=== image_src_sub is #{image_name}"
        `wget -cO - "#{image_src}" > "public/blog_images/#{image_name}"`
        puts "=== blog_content is #{blog_content}"
      end
    end
    blog_content = to_get_content.to_s.gsub("#{remote_uploads_url}", "###MY_IMAGE_SITE###/images/")
    puts "=== blog_content is #{blog_content}"

    #username = doc.css('span[class="username cell"]').text
    #puts "=== username is #{username}"

    #blog.update author: author, author_url: author_url, content: blog_content
    puts '===start 30'
    sleep 30
    puts '==end 30'
  end
end
