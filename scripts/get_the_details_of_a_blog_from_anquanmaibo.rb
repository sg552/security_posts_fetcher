ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'open-uri'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

@logger = Logger.new("#{Rails.root}/log/get_the_details_of_a_blog_from_anquanmaibo.log")
blogs = Blog.where('source_website = ?', 'anquanmaibo').all
blogs.each do |blog|
  @logger.info "=== before update blog: #{blog.inspect}"
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
  image_remote_and_local_hash = {}
  if images != ''
    images.to_ary.each do |image|
      image_src = image.attr("src") rescue ''
      temp_image_name = image_src.sub("#{remote_uploads_url}", '') rescue ''
      image_name = image_src.to_s.gsub('/', '_').gsub(':', '')
      image_local = "###MY_IMAGE_SITE###/images/#{image_name}"
      image_remote_and_local_hash.store(image_src, image_local)
      `wget -cO - "#{image_src}" > "public/blog_images/#{image_name}"`
    end
  end
  @logger.info "image_remote_and_local_hash #{image_remote_and_local_hash}"
  blog_content = to_get_content.to_s
  @logger.info "=== before replace image_url blog_content is #{blog_content}"
  image_remote_and_local_hash.map {|key, value|
    if key.to_s.include?('http')
      @logger.info "==== key #{key} value: #{value}"
      blog_content = blog_content.to_s.gsub("#{key.to_s}", "#{value.to_s}")
    end
    @logger.info "=== after replace image_url blog_content is #{blog_content}"
  }
  @logger.info "=== end map content is #{blog_content}"

  special_column_name = doc.css('span[class="tag mr20"] a').text
  @logger.info "special_column_name #{special_column_name}"
  special_column_local = SpecialColumn.where('name = ? and source_website = ?', special_column_name, 'anquanmaibo').first
  if special_column_local.blank?
    special_column_local = SpecialColumn.create name: special_column_name, source_website: 'anquanmaibo'
  end
  doc.css('span[class="tags"] a').each do |a|
    category_name = a.text
    @logger.info "=== category_name #{category_name}"
    Category.create name: category_name, blog_id: blog.id, special_column_id: special_column_local.id
  end

  blog.update author: author, author_url: author_url, content: blog_content, views: views, created_at: created_at
  @logger.info "=== after update blog: #{blog.inspect}"
  @logger.info '===start 30'
  sleep 30
  @logger.info '==end 30'
end
