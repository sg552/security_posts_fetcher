ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

@logger = Logger.new("#{Rails.root}/log/get_blogs_from_kanxue.log")
url = "https://www.kanxue.com/"
kanxue_url = "www.kanxue.com"
post_html = "/homepost-morearticle.htm"
Rails.logger.info "===#{url}"
headers = {
  'Host': 'www.kanxue.com',
  'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Gecko/20100101 Firefox/106.0',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
  'Accept-Language': 'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
  'Accept-Encoding': 'gzip, deflate, br',
  'Referer': 'https://ctf.pediy.com/',
  'Connection': 'keep-alive',
  'Cookie': 'PHPSESSID=8a82f36e5666eb8fd519769699f9ff2e; __jsluid_s=61f26b9d4fbbe7b03612225e7a61b899; Hm_lvt_820e73ad7ccba42be0e5b528c537e327=1666926727; Hm_lpvt_820e73ad7ccba42be0e5b528c537e327=1666926742',
  'Upgrade-Insecure-Requests': '1',
  'Sec-Fetch-Dest': 'document',
  'Sec-Fetch-Mode': 'navigate',
  'Sec-Fetch-Site': 'cross-site',
  'Sec-Fetch-User': '?1'
}

response = HTTParty.get url, :headers => headers
@logger.info "===response.code, #{response.code} ===response.headers is #{response.headers}"
doc = Nokogiri::HTML(response.body)
@logger.info "=== doc is #{doc}"
doc.css('div[class="media p-4 home_article bg-white"]').each do |title|
  @logger.info "=== title is #{title}"
  temp_image_url = title.css('div[class="mr-4 article-img"]').to_s.split('url(').last.split(')').first
  image_url = "https:#{temp_image_url}"
  blog_title = title.css('h4').text.strip
  blog_url = title.css('div[class="media-body position-relative"] a')[0]["href"]
  @logger.info "=== image_url: #{image_url} blog_title #{blog_title} blog_url :#{blog_url}"

  blog = Blog.where('blog_url = ?', blog_url).first
  if blog.blank?
    Blog.create title: blog_title, blog_url: blog_url, image_url: image_url, source_website: 'kanxue'
  end

end
@logger.info "== blog.all.size #{Blog.all.size}"
