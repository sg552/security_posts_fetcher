ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'open-uri'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

@logger = Logger.new("#{Rails.root}/log/get_blogs_from_xianzhi.log")
blogs = Blog.all
blogs.each do |blog|
  if blog.views.blank? && blog.source_website.include?('xianzhi')
    @logger.info "== blog.inspect #{blog.inspect}"
    xz_aliyun_url = "https://xz.aliyun.com"
    headers = {
      'Host': 'xz.aliyun.com',
      'User-Agent':'Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Gecko/20100101 Firefox/106.0',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Cookie': '_uab_collina=166685393219670430831043; cna=RVW0Gru+SF8CAbf+PUgM1No+; isg=BFtbblO4vLmFnsEKbfmff_yf6bbFMG8ylXRJUU2YN9pxLHsO1QD_gnmtxgyiF8cq; tfstk=c6s1BgYekLAUmYOElCwUgm9XH3KAC9kWhPOGC5gTpd9UD7e2801D80RWhSQmMnJvd; l=eBQbNcplL4_DNoYTBOfahurza77OSIOYYuPzaNbMiOCPOJ1B54aVW6yGZuY6C31Vh6f2R35fl999BeYBYQd-nxvtGwBLE8Dmn; t=7a2881edec39e7fbff8a76ef506ff586; aliyun_choice=CN; currentRegionId=cn-hangzhou; login_aliyunid_pk=1387746726135732; aliyun_lang=zh; csrftoken=K4A139LURfgcaGcrq6WrjliBOy1CKCSpvTROW1dQLG8mWVfc2HThwMItIDs6t9mE; aliyun_country=CN; aliyun_site=CN; _samesite_flag_=true; cookie2=1e17b3ab40e7857adf07c6459ec22c50; _tb_token_=586ee33685aed; help_csrf=lKQjKDQXRXVEgYiR%2Bw2Muojzm720X6QqwRcDVfMLl63%2BmF3P7wtgdm7ym7jFoYHzqMuw0bSXuEF8UvL4Ki40nMIeeYnPhoiAYNHPxx6mDhJ9fOLFTQ4jU4%2F9MWDEDezlLfrNIjovE1Ie3V7GtlJIog%3D%3D; cr_token=45ab28d1-1ea0-4e26-9ea1-3f030c4ed0df; login_aliyunid_csrf=_csrf_tk_1947266857599452; acw_tc=2f624a5116672192926737862e26a635cc3f579cdb99f43528a5a033ec5f57',
      'Upgrade-Insecure-Request': '1',
      'Sec-Fetch-Des': 'document',
      'Sec-Fetch-Mod': 'navigate',
      'Sec-Fetch-Site': 'same-origin',
      'Sec-Fetch-Use': '?1'
    }

    response = HTTParty.get blog.blog_url, :headers => headers
    @logger.info "===response.code, #{response.code} === response.headers is #{response.headers}"
    doc = Nokogiri::HTML(response.body)
    @logger.info "=== doc is #{doc} doc.class: #{doc.class}"

    to_get_author = doc.css('span[class="info-left"] a')
    #author_url = "#{xz_aliyun_url}#{to_get_author[0]["href"]}"
    author_url = "#{xz_aliyun_url}#{to_get_author[0]}"
    to_get_author = doc.css('span[class="info-left"] a')
    @logger.info "==  author_url is #{author_url}"

    to_get_content = doc.css('div#topic_content') rescue ''
    @logger.info "==  to_get_content is #{to_get_content}"
    #获得博客内容的所有图片
    images = doc.css('div#topic_content img') rescue ''
    @logger.info "=== images is #{images}"
    #为了保存图片
    image_remote_and_local_hash = {}
    if images != ''
      images.to_ary.each do |image|
        image_src = image.attr("src")
        #保存本地图片的名称
        image_name = image_src.to_s.gsub('/', '_').gsub(':', '')
        image_local = "###MY_IMAGE_SITE###/images/#{image_name}"
        image_remote_and_local_hash.store(image_src, image_local)
        `wget -cO - "#{image_src}" > "public/blog_images/#{image_name}"`
      end
    end
    @logger.info "image_remote_and_local_hash #{image_remote_and_local_hash}"
    #获得博客的内容
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

    username = doc.css('span[class="username cell"]').text
    @logger.info "=== username is #{username}"

    to_get_created_at = doc.css('span[class="info-left"] span')
    temp_to_get_created_at = doc.css('span[class="info-left"] span')[5]
    #获得浏览数
    views = to_get_created_at[4].text.split('数').last.to_i
    #获得创建时间
    created_at = doc.css('span[class="info-left"] span')[2].text
    @logger.info "==  to_get_created_at is #{to_get_created_at}"
    @logger.info "==  views : #{views}  created_at : #{created_at}"

    to_get_category = doc.css('span[class="content-node"] a').each do |a|
      category_name  = a.text
      @logger.info "==  category_name : #{category_name}"
      category = Category.where('name = ? and blog_id = ?', category, blog.id).first
      xianzhi_anquanjishu_column = ["众测渗透", "漏洞分析", "WEB安全", "二进制安全", "移动安全", "IoT安全", "企业安全", "区块链安全", "密码学", "CTF", "安全工具", "资源分享", "技术讨论"].to_s
      xianzhi_qingbao_column = ["情报"].to_s
      xianzhi_gonggao_column = ["社区公告"].to_s
      if xianzhi_anquanjishu_column.include?category_name
        special_column_local = SpecialColumn.where('name = ? and source_website = ?', "安全技术", 'xianzhi').first
      elsif xianzhi_qingbao_column.include?category_name
        special_column_local = SpecialColumn.where('name = ? and source_website = ?', "先知情报", 'xianzhi').first
      elsif xianzhi_gonggao_column.include?category_name
        special_column_local = SpecialColumn.where('name = ? and source_website = ?', "社区公告", 'xianzhi').first
      end
      if category.blank?
        Category.create name: category_name, blog_id: blog.id, special_column_id: special_column_local.id
      end
      @logger.info "==  category: #{category.inspect}"
      puts "==  category: #{category.inspect}"
    end
    @logger.info "==  to_get_category: #{to_get_category}"
    blog.update author: username, content: blog_content, created_at: created_at, source_website: 'xianzhi', views: views

    @logger.info "===start 30  ===after update blog: #{blog.inspect}"
    sleep 30
    @logger.info '==end 30'
  end
end
