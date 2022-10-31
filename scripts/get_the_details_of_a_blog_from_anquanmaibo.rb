ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'open-uri'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

@logger = Logger.new("#{Rails.root}/log/get_the_details_of_a_blog_from_anquanmaibo.log")
blogs = Blog.all
blogs.each do |blog|
  @logger.info "=== before update blog: #{blog.inspect}"
  if blog.views.blank? && blog.blog_url.include?('secpulse')
    @logger.info "== blog.inspect #{blog.inspect}"
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
    @logger.info "===response.code, #{response.code} === response.headers is #{response.headers}"
    doc = Nokogiri::HTML(response.body)
    @logger.info "=== doc is #{doc} doc.class#{doc.class}"

    to_get_titile = doc.css('h1').text rescue ''
    @logger.info "==== to_get_titile: #{to_get_titile}"
    to_get_author = doc.css('span[class="writer"] a')
    author_url = "#{to_get_author[0]["href"]}"
    #获得作者
    author = "#{to_get_author[0].text}"
    @logger.info "==== to_get_author : #{to_get_author}==== author_url: #{author_url}==== author: #{author}"
    created_at = doc.css('div[class="right fr"] span')[0].text
    views = doc.css('div[class="right fr"] span')[1].text.sub(',', '').to_i
    @logger.info "==== created_at: #{created_at} views: #{views}"

    to_get_content = doc.css('div[class="left-9-code"]') rescue ''
    @logger.info "==  to_get_content is #{to_get_content}"
    images = to_get_content.css('img') rescue ''
    @logger.info "=== images is #{images}"
    blog_content = ''
    remote_uploads_url = "https://secpulseoss.oss-cn-shanghai.aliyuncs.com/wp-content/uploads/"
    if images != ''
      images.to_ary.each do |image|
        @logger.info "=== image is #{image}"
        image_src = image.attr("src") rescue ''
        @logger.info "--- image_src is #{image_src} "
        temp_image_name = image_src.sub("#{remote_uploads_url}", '') rescue ''
        image_name = temp_image_name.gsub('/', '_')
        @logger.info "=== image_src_sub is #{image_name}"
        `wget -cO - "#{image_src}" > "public/blog_images/#{image_name}"`
      end
    end
    blog_content = to_get_content.to_s.gsub("#{remote_uploads_url}", "###MY_IMAGE_SITE###/images/")
    @logger.info "=== blog_content is #{blog_content}"

    category_name = doc.css('div[class="left fl"] span')[0].css('a').text
    category_local = Category.where('blog_id = ? and name = ?', blog.id, category_name).first
    if category_local.blank?
      Category.create blog_id: blog.id, name: category_name
    end
    @logger.info "=== category_name is #{category_name}"
    puts "=== category_name is #{category_name}"

    blog.update author: author, author_url: author_url, content: blog_content, views: views, created_at: created_at
    @logger.info "=== after update blog: #{blog.inspect}"
    @logger.info '===start 30'
    sleep 30
    @logger.info '==end 30'
  end
end
