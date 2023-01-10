require 'nokogiri'
require 'rubygems'

class UpdateXianzhiBlogUsingProxyJob < ApplicationJob
  queue_as :default
  retry_on UpdateXianzhiBlogUsingProxyJob, wait: 1.minutes, attempts: 5

  def save_images images
    image_remote_and_local_hash = {}
    images.to_ary.each do |image|
      image_src = image.attr("src")
      # 保存本地图片的名称
      image_name = image_src.to_s.gsub('/', '_').gsub(':', '')
      image_local = "###MY_IMAGE_SITE###/images/#{image_name}"
      image_remote_and_local_hash.store(image_src, image_local)
      proxy = Proxy.where('expiration_time > ?', Time.now).all.shuffle.first
      Rails.logger.info "==== in save_images proxy ip: #{proxy.external_ip rescue ''}"
      command_get_image = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{image_src} --output public/blog_images/#{image_name}}
      Rails.logger.info "======  command_get_image: #{command_get_image}"
      result = `#{command_get_image}`
      Rails.logger.info "=== result #{result} command_get_image: #{command_get_image}"
    end
    return image_remote_and_local_hash
  end

  def create_category blog_id, category_name
    if category_name.present?
      xianzhi_qingbao_column = ["情报", "先知情报"].to_s
      xianzhi_gonggao_column = ["社区公告"].to_s
      special_column_local = ''
      if category_name.include?("安全")
        special_column_local = SpecialColumn.where('name = ? and source_website = ?', "安全技术", 'xianzhi').first
      elsif category_name.include?("社区")
        special_column_local = SpecialColumn.where('name = ? and source_website = ?', "社区公告", 'xianzhi').first
      end
      Rails.logger.info "==== id : #{special_column_local.id rescue ''}"
      category = Category.where('name = ? and blog_id = ?', category_name, blog_id).first
      Rails.logger.info "======  category: #{category.inspect}"
      if category.blank?
        Category.create name: category_name, blog_id: blog_id, special_column_id: special_column_local.id
      end
      Rails.logger.info "======  category_name : #{category_name} special_column_local.id : #{special_column_local.id}"
    end
  end

  def perform(args)
    Rails.logger = Logger.new("log/update_xianzhi_blog_using_proxy_job.log")
    blog = args[:blog]
    Rails.logger.info "=====in job before update blog_url :#{blog.blog_url }"
    proxy = Proxy.where('expiration_time > ?', Time.now).all.shuffle.first
    if blog.blog_url.present? && blog.content.blank?
      command_get_page = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{blog.blog_url}}
    end
    Rails.logger.info "====== command_get_page: #{command_get_page}"
    blog_html_doc = `#{command_get_page}`
    blog_show_doc = Nokogiri::HTML(blog_html_doc)
    to_get_content = blog_show_doc.css('div#topic_content') rescue ''
    to_get_content = blog_show_doc.css('div#topic_content') rescue ''
    to_get_author = blog_show_doc.css('span[class="info-left"] a')
    author_url = "https://xz.aliyun.com/#{to_get_author[0]}"
    Rails.logger.info "==  to_get_content is #{to_get_content}  author_url #{author_url}"
    # 获得博客内容的所有图片
    images = blog_show_doc.css('div#topic_content img') rescue ''
    Rails.logger.info "=== images is #{images}"
    # 为了保存图片
    image_remote_and_local_hash = save_images images if images.present?
    Rails.logger.info "====== image_remote_and_local_hash #{image_remote_and_local_hash}"
    # 获得博客的内容
    if to_get_content.present? && image_remote_and_local_hash.present?
      blog_content = to_get_content.to_s
      Rails.logger.info "=== before replace image_url blog_content is #{blog_content}"
      image_remote_and_local_hash.map {|key, value|
        if key.to_s.include?('http')
          Rails.logger.info "==== key #{key} value: #{value}"
          blog_content = blog_content.to_s.gsub("#{key.to_s}", "#{value.to_s}")
        end
        Rails.logger.info "=== after replace image_url blog_content is #{blog_content}"
      }
      Rails.logger.info "=== end map content is #{blog_content}"
    elsif to_get_content.present?
      blog_content = to_get_content.to_s
    end

    username = blog_show_doc.css('span[class="username cell"]').text rescue ''
    Rails.logger.info "=== username is #{username}"
    to_get_created_at = blog_show_doc.css('span[class="info-left"] span')
    temp_to_get_created_at = blog_show_doc.css('span[class="info-left"] span')[5] rescue ''
    # 获得浏览数
    views = to_get_created_at[4].text.split('数').last.to_i rescue ''
    # 获得创建时间
    created_at = blog_show_doc.css('span[class="info-left"] span')[2].text rescue ''
    Rails.logger.info "======  to_get_created_at #{to_get_created_at}  views : #{views}  created_at : #{created_at}"
    if created_at.present?
      blog.update source_website: 'xianzhi', author: username, content: blog_content, created_at: created_at, views: views
    end
    category_name = blog_show_doc.css('span[class="content-node"] a').text rescue ''
    Rails.logger.info "========= category_name:#{category_name}"
    create_category blog.id, category_name
  end
end

