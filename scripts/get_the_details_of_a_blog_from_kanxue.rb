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
  if blog.content.blank? && blog.blog_url.include?('article')
    puts "== blog.inspect #{blog.inspect}"
    kanxue_url = "https://www.kanxue.com/"
    puts "=== blog.blog_url : #{blog.blog_url}"
    headers = {
      'Host': 'bbs.pediy.com',
      'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Gecko/20100101 Firefox/106.0',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Cookie': 'bbs_sid=6fe6d893ccc97dd453efb5c77932f571; __jsluid_s=33efc98ca86b7d6d182f48c94a5f8824; __utma=181774708.684683680.1666926694.1666926694.1666938778.2; __utmc=181774708; __utmz=181774708.1666926694.1.1.utmcsr=baidu|utmccn=(organic)|utmcmd=organic; _ga=GA1.2.1524884775.1666926736; _gid=GA1.2.1089669572.1666926736; __jsluid_h=213acb53f4c527a280d8e4207e0ba8e4; __utmb=181774708.3.10.1666938778; __utmt=1',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1'
    }
    if blog.blog_url.include? 'https:http'
      new_blog_url = blog.blog_url.sub("https:", '')
      blog.update blog_url: new_blog_url
      puts "=== blog: #{blog.inspect}"
    end

    response = HTTParty.get blog.blog_url, :headers => headers
    puts "===response.code, #{response.code} === response.headers is #{response.headers}"
    doc = Nokogiri::HTML(response.body)
    puts "=== doc is #{doc} doc.class#{doc.class}"

    to_get_titile = doc.css('h3[class="break-all subject m-0"]').text.strip rescue ''
    puts "=== to_get_titile is #{to_get_titile}"

    to_get_content = doc.css('div[isfirst="1"]') rescue ''
    puts "==  to_get_content is #{to_get_content}"
    images = doc.css("div[class='message '] img") rescue ''
    puts "=== images is #{images}"
    blog_content = ''
    if images != ''
      images.to_ary.each do |image|
        puts "=== image is #{image}"
        image_src = image.attr("src") rescue ''
        puts "--- image_src is #{image_src} "
        image_name = image_src.sub('upload/attach/202210/', '') rescue ''
        puts "=== image_src_sub is #{image_name}"
        `wget -cO - "https://bbs.pediy.com/#{image_src}" > "public/blog_images/#{image_name}"`
        puts "=== blog_content is #{blog_content}"
      end
    end
    blog_content = to_get_content.to_s.gsub("/upload/attach/202210/", "###MY_IMAGE_SITE###/images/")
    puts "=== blog_content is #{blog_content}"

    username = doc.css('a[class="btn bg-white w-100 py-1"]') rescue ''
    to_get_author = username[0]["href"] rescue ''
    author = to_get_author.split('=').last
    puts "=== username is #{username} author: #{author}"
    blog.update author: author, content: blog_content
    puts "==== blog: #{blog.inspect}"
    puts '===start 30'
    sleep 30
    puts '==end 30'
  end
end
