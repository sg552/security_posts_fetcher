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
  if blog.content.blank?
    puts "== blog.inspect #{blog.inspect}"
    xz_aliyun_url = "https://xz.aliyun.com"
    url = "https://xz.aliyun.com/t/11774"
    puts "===url is #{url}"
    headers = {
      'Host': 'xz.aliyun.com',
      'User-Agent':'Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Gecko/20100101 Firefox/106.0',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Cookie': 'cna=RVW0Gru+SF8CAbf+PUgM1No+; isg=BEdHq6Tn6Ie02G3OWVXr83B71fIRTBsuiRDlFRk0Y1b9iGdKIRyrfoVJKsjWe_Om; tfstk=caTFBI21CoU6APLNlNbyuurAAnQdZJdHZP5fxYv_MbRTH9sGixyRs921__NaEMf..; l=eBQbNcplL4_DN0VYBOfahurza77OSIOYYuPzaNbMiOCPOXfp5o2GW6y16bT9C31Vh6xvR35fl999BeYBYQd-nxvTkjOadJMmn; t=7a2881edec39e7fbff8a76ef506ff586; aliyun_choice=CN; currentRegionId=cn-hangzhou; login_aliyunid_pk=1387746726135732; aliyun_lang=zh; aliyun_country=CN; aliyun_site=CN; login_aliyunid_csrf=_csrf_tk_1133266830721115; _samesite_flag_=true; cookie2=1e17b3ab40e7857adf07c6459ec22c50; _tb_token_=586ee33685aed',
      'Upgrade-Insecure-Request': '1',
      'Sec-Fetch-Des': 'document',
      'Sec-Fetch-Mod': 'navigate',
      'Sec-Fetch-Sit': 'cross-site',
      'Sec-Fetch-Use': '?1'
    }

    response = HTTParty.get blog.blog_url, :headers => headers
    puts "===response.code, #{response.code} === response.headers is #{response.headers}"
    doc = Nokogiri::HTML(response.body)
    puts "=== doc is #{doc} doc.class#{doc.class}"

    to_get_author = doc.css('span[class="info-left"] a')
    author_url = "#{xz_aliyun_url}#{to_get_author[0]["href"]}"
    to_get_author = doc.css('span[class="info-left"] a')
    puts "==  author_url is #{author_url}"

    to_get_content = doc.css('div#topic_content') rescue ''
    puts "==  to_get_content is #{to_get_content}"
    images = doc.css('div#topic_content img') rescue ''
    puts "=== images is #{images}"
    blog_content = ''
    if images != ''
      images.to_ary.each do |image|
        puts "=== image is #{image}"
        image_src = image.attr("src") rescue ''
        puts "--- image_src is #{image_src} "
        image_name = image_src.sub('https://xzfile.aliyuncs.com/media/upload/picture/', '') rescue ''
        puts "=== image_src_sub is #{image_name}"
        `wget -cO - "#{image_src}" > "public/blog_images/#{image_name}"`
        puts "=== blog_content is #{blog_content}"
      end
    end
    blog_content = to_get_content.to_s.gsub("https://xzfile.aliyuncs.com/media/upload/picture/", "###MY_IMAGE_SITE###/images/")
    puts "=== blog_content is #{blog_content}"

    username = doc.css('span[class="username cell"]').text
    puts "=== username is #{username}"

    blog.update author: username, content: blog_content
    puts '===start 30'
    sleep 30
    puts '==end 30'
  end
end
