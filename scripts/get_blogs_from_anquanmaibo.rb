ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

@logger = Logger.new("#{Rails.root}/log/get_blogs_from_anquanmaibo.log")
i = 1
loop do
  url = "https://www.secpulse.com/page/#{i}"
  kanxue_url = "www.kanxue.com"
  post_html = "/homepost-morearticle.htm"
  Rails.logger.info "===#{url}"
  headers = {
    'Host': 'www.secpulse.com',
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Gecko/20100101 Firefox/106.0',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Cookie': 'Hm_lvt_7f4cc5524dcb1aec487b4266c18bae48=1666943504; Hm_lpvt_7f4cc5524dcb1aec487b4266c18bae48=1666944123',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'cross-site',
    'Pragma': 'no-cache',
    'Cache-Control': 'no-cache',
    'Sec-Fetch-User': '?1'
  }

  response = HTTParty.get url, :headers => headers
  @logger.info "===response.code, #{response.code} ===response.headers is #{response.headers}"
  doc = Nokogiri::HTML(response.body)
  @logger.info "=== doc is #{doc}"
  doc.css('div#ajax_content li').each do |title|
    @logger.info "=== title is #{title}"
    #title  url
    temp_blog_url = title.css('div[class="slide #d9534f"] a')[0]["href"] rescue ''
    temp_blog_title = title.css('div[class="slide_text fl"] a')[0].text rescue ''
    @logger.info "== temp_blog_title is #{temp_blog_title}"
    @logger.info "== temp_blog_url is #{temp_blog_url}"
    #封面
    image_url = title.css('div[class="slide #d9534f"] img')[0]["src"] rescue ''
    @logger.info "== image_url is #{image_url}"

    temp_image_name_local = image_url.sub('https://secpulseoss.oss-cn-shanghai.aliyuncs.com/wp-content/uploads/', '') rescue ''
    image_name_local = temp_image_name_local.gsub('/', '_') rescue ''
    @logger.info "=== image_name_local is #{image_name_local}"
    `wget -cO - "#{image_url}" > "public/blog_images/#{image_name_local}"`
    image_url_local = "###MY_IMAGE_SITE###/images/#{image_name_local}"

    blog = Blog.where('blog_url = ?', temp_blog_url).first
    @logger.info "===before save blog: #{blog.inspect}"
    if blog == nil
      Blog.create title: temp_blog_title.strip, blog_url: temp_blog_url, image_url: image_url_local, resource_website: 'anquanmaibo'
      @logger.info "=== after save blog: #{blog.inspect}"
    end
  end
  @logger.info "== blog.all.size #{Blog.all.size}"
  i = i + 1
  if i > 10
    @logger.info "=== i is #{i} end"
    break
  end
  @logger.info "=== i is #{i} start sleep 10"
  sleep 10
end
