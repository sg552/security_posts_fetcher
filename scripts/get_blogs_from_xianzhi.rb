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
    'Cookie': 'cna=RVW0Gru+SF8CAbf+PUgM1No+; isg=BEdHq6Tn6Ie02G3OWVXr83B71fIRTBsuiRDlFRk0Y1b9iGdKIRyrfoVJKsjWe_Om; tfstk=caTFBI21CoU6APLNlNbyuurAAnQdZJdHZP5fxYv_MbRTH9sGixyRs921__NaEMf..; l=eBQbNcplL4_DN0VYBOfahurza77OSIOYYuPzaNbMiOCPOXfp5o2GW6y16bT9C31Vh6xvR35fl999BeYBYQd-nxvTkjOadJMmn; t=7a2881edec39e7fbff8a76ef506ff586; aliyun_choice=CN; currentRegionId=cn-hangzhou; login_aliyunid_pk=1387746726135732; aliyun_lang=zh; aliyun_country=CN; aliyun_site=CN; login_aliyunid_csrf=_csrf_tk_1133266830721115; _samesite_flag_=true; cookie2=1e17b3ab40e7857adf07c6459ec22c50; _tb_token_=586ee33685aed',
    'Upgrade-Insecure-Request': '1',
    'Sec-Fetch-Des': 'document',
    'Sec-Fetch-Mod': 'navigate',
    'Sec-Fetch-Sit': 'cross-site',
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
      Blog.create title: blog_title.strip, blog_url: blog_url
    end
    @logger.info "== blog.all.size #{Blog.all.size}"
  end

  #doc.css('p[class="topic-info"] a').each do |user|
  #  blog_author = user.text rescue ''
  #  @logger.info "=== user is #{user} blog_author is #{blog_author}"
  #end
  i = i + 1
  sleep 30
  @logger.info "=====i is #{i} sleep 30"
  if i > 10
    @logger.info "=== end "
    break
  end
end
