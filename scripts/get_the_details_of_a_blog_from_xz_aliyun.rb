ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'open-uri'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

@logger = Logger.new("#{Rails.root}/log/get_the_detials_of_a_blog_from_xz_aliyun.log")
blogs = Blog.all
blogs.each do |blog|
  if blog.views.blank?
    @logger.info "== blog.inspect #{blog.inspect}"
    xz_aliyun_url = "https://xz.aliyun.com"
    url = "https://xz.aliyun.com/t/11774"
    @logger.info "===url is #{url}"
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
    @logger.info "===response.code, #{response.code} === response.headers is #{response.headers}"
    doc = Nokogiri::HTML(response.body)
    @logger.info "=== doc is #{doc} doc.class: #{doc.class}"

    to_get_author = doc.css('span[class="info-left"] a')
    author_url = "#{xz_aliyun_url}#{to_get_author[0]["href"]}"
    to_get_author = doc.css('span[class="info-left"] a')
    @logger.info "==  author_url is #{author_url}"

    to_get_content = doc.css('div#topic_content') rescue ''
    @logger.info "==  to_get_content is #{to_get_content}"
    #获得博客内容的所有图片
    images = doc.css('div#topic_content img') rescue ''
    @logger.info "=== images is #{images}"
    blog_content = ''
    if images != ''
      images.to_ary.each do |image|
        @logger.info "=== image is #{image}"
        image_src = image.attr("src") rescue ''
        @logger.info "--- image_src is #{image_src} "
        image_name = image_src.sub('https://xzfile.aliyuncs.com/media/upload/picture/', '') rescue ''
        @logger.info "=== image_src_sub is #{image_name}"
        `wget -cO - "#{image_src}" > "public/blog_images/#{image_name}"`
        @logger.info "=== blog_content is #{blog_content}"
      end
    end
    #获得博客的内容
    blog_content = to_get_content.to_s.gsub("https://xzfile.aliyuncs.com/media/upload/picture/", "###MY_IMAGE_SITE###/images/")
    @logger.info "=== blog_content is #{blog_content}"

    username = doc.css('span[class="username cell"]').text
    @logger.info "=== username is #{username}"

    to_get_created_at = doc.css('span[class="info-left"] span')
    temp_to_get_created_at = doc.css('span[class="info-left"] span')[5]
    #获得浏览数
    views = doc.css('span[class="info-left"] span')[5].text.split('浏览数').last
    #获得创建时间
    created_at = doc.css('span[class="info-left"] span')[2].text
    @logger.info "==  to_get_created_at is #{to_get_created_at}"
    @logger.info "==  views : #{views.to_i}  created_at : #{created_at}"

    to_get_category = doc.css('span[class="content-node"] a').each do |a|
      category_name  = a.text
      @logger.info "==  category_name : #{category_name}"
      category = Category.where('name = ? and blog_id = ?', category, blog.id).first
      if category.blank?
        Category.create name: category, blog_id: blog.id
      end
      @logger.info "==  category: #{category.inspect}"
      puts "==  category: #{category.inspect}"
    end
    @logger.info "==  to_get_category: #{to_get_category}"
    puts "==  to_get_category: #{to_get_category}"

    blog.update author: username, content: blog_content, source_website: 'xianzhi',created_at: created_at, source_website: 'xianzhi', views: views.to_i

    @logger.info '===start 30'
    sleep 30
    @logger.info '==end 30'
  end
end
