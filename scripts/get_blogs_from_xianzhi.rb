ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

@logger = Logger.new("#{Rails.root}/log/get_blogs_from_xianzhi.log")
i = 1
loop do
  url = "https://xz.aliyun.com/?page=#{i}"
  xz_url = "https://xz.aliyun.com"
  Rails.logger.info "===#{url}"
  headers = {
    'Host': 'xz.aliyun.com',
    'User-Agent':'Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Gecko/20100101 Firefox/106.0',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Cookie': 'cna=RVW0Gru+SF8CAbf+PUgM1No+; isg=BFtbblO4vLmFnsEKbfmff_yf6bbFMG8ylXRJUU2YN9pxLHsO1QD_gnmtxgyiF8cq; tfstk=c6s1BgYekLAUmYOElCwUgm9XH3KAC9kWhPOGC5gTpd9UD7e2801D80RWhSQmMnJvd; l=eBQbNcplL4_DNoYTBOfahurza77OSIOYYuPzaNbMiOCPOJ1B54aVW6yGZuY6C31Vh6f2R35fl999BeYBYQd-nxvtGwBLE8Dmn; t=7a2881edec39e7fbff8a76ef506ff586; aliyun_choice=CN; currentRegionId=cn-hangzhou; login_aliyunid_pk=1387746726135732; aliyun_lang=zh; csrftoken=K4A139LURfgcaGcrq6WrjliBOy1CKCSpvTROW1dQLG8mWVfc2HThwMItIDs6t9mE; aliyun_country=CN; aliyun_site=CN; acw_tc=2f624a4816672956703872149e29c8f8729c03ea7d1e824af4b95e67e2362d; acw_sc__v2=6360e9be832b995754c58b7a9f724516fd15cd23',
    'Upgrade-Insecure-Request': '1',
    'Sec-Fetch-Des': 'document',
    'Sec-Fetch-Mod': 'navigate',
    'Sec-Fetch-Site': 'same-origin',
    'Sec-Fetch-Use': '?1'
  }

  response = HTTParty.get url, :headers => headers
  @logger.info "===response.code, #{response.code} ===response.headers is #{response.headers}"
  doc = Nokogiri::HTML(response.body)
  @logger.info "=== doc is #{doc}"
  doc.css('p[class="topic-summary"] a').each do |title|
    @logger.info "=== title is #{title}"
    blog_url = "#{xz_url}#{title["href"]}" rescue ''
    @logger.info "== blog_url is #{blog_url}"

    blog_title = title.text rescue ''
    @logger.info "=== blog_title is #{blog_title}"
    if blog_title != ''
      Blog.create title: blog_title.strip, blog_url: blog_url, source_website: 'xianzhi'
    end
    @logger.info "== blog.all.size #{Blog.all.size}"
  end

  i = i + 1
  sleep 30
  @logger.info "=====i is #{i} sleep 30"
  if i > 10
    @logger.info "=== end "
    break
  end
end
