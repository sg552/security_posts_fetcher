require 'nokogiri'
require 'rubygems'

class UpdateKanxueBlogUsingProxyJob < ApplicationJob
  queue_as :default
  retry_on UpdateKanxueBlogUsingProxyJob, wait: 10.seconds, attempts: 5

  def save_images images
    Rails.logger.info "=== images is #{images}"
    image_remote_and_local_hash = {}
    images.to_ary.each do |image|
      image_src = image.attr("src")
      # 保存本地图片的名称
      image_name = image_src.to_s.gsub('/', '_').gsub(':', '')
      image_local = "###MY_IMAGE_SITE###/images/#{image_name}"
      image_remote_and_local_hash.store(image_src, image_local)
      Rails.logger.info "==== in save_images proxy ip: #{proxy.external_ip rescue ''}"
      proxy = Proxy.where('expiration_time > ?', Time.now).all.shuffle.first
      #command_get_image = %Q{curl -s --socks5 #{proxy.ip}:#{proxy.port} #{image_src} --output public/blog_images/#{image_name}}
      if image_src.include? 'http'
        command_get_image = %Q{curl #{image_src} --output public/blog_images/#{image_name}}
      else
        command_get_image = %Q{curl https://zhuanlan.kanxue.com/#{image_src} --output public/blog_images/#{image_name}}
      end
      Rails.logger.info "======  command_get_image: #{command_get_image}"
      result = `#{command_get_image}`
      Rails.logger.info "=== result #{result} command_get_image: #{command_get_image}"
    end
    return image_remote_and_local_hash
  end

  def create_category blog_id, category_names
    category_names.each do |a|
      Rails.logger.info "=== a is #{a}"
      category_name = a.text
      Rails.logger.info "=== category_name is #{category_name}"
      category_local = Category.where('blog_id = ? and name = ?', blog.id, category_name).first
      Rails.logger.info "=== category_local #{category_local.inspect}"
      if category_local.blank?
        Category.create blog_id: blog.id, name: category_name
      end
    end
  end

  def perform(args)
    Rails.logger = Logger.new("log/update_kanxue_blogs_using_job.log")
    blog = args[:blog]
    Rails.logger.info "==== in job, start update kanxue blog: #{blog.inspect}"
    if blog.content.blank?
      Rails.logger.info "== blog.inspect #{blog.inspect}"

      blog_url = ''
      if blog.blog_url.include? 'article'
        blog_url = "https:#{blog.blog_url}"
      else
        blog_url = blog.blog_url
      end

      proxy = Proxy.where('expiration_time > ?', Time.now).all.shuffle.first
      Rails.logger.info "==== proxy ip: #{proxy.external_ip rescue 'nil'}"
      #command_to_get_blog_content= %Q{curl --socks5 #{proxy.ip}:#{proxy.port} #{blog_url}}
      command_to_get_blog_content= %Q{curl #{blog_url}}
      Rails.logger.info "=== command_to_get_blog_content: #{command_to_get_blog_content}"
      result = `#{command_to_get_blog_content}`

      doc = Nokogiri::HTML(result)
      Rails.logger.info "=== kanxue blog show page is #{doc}"

      title = doc.css('h3').text.strip rescue ''
      author = doc.css('div[class="col"] span')[0].text.strip rescue ''
      #created_at = doc.css('span[class="date text-grey ml-1"]').text.strip rescue ''
      #created_at = doc.css('div[class="col"] span')[1].text.strip rescue ''
      #created_at = doc.css('span[class="date text-grey ml-3"]')[1].text rescue ''
      created_at = doc.css('div[class="col"] span')[1].text rescue ''
      views = doc.css('div[class="col"] span')[2].text.to_i rescue ''

      images = doc.css("div[class='message '] img") rescue ''
      image_remote_and_local_hash = save_images images if images.present?
      Rails.logger.info "====== image_remote_and_local_hash #{image_remote_and_local_hash}"

      to_get_content = doc.css('div[isfirst="1"]') rescue ''
      Rails.logger.info "==  to_get_content is #{to_get_content}"
      images = doc.css("div[class='message '] img") rescue ''
      Rails.logger.info "=== images is #{images}"
      blog_content = ''
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
      Rails.logger.info "=== blog_content is #{blog_content}"
      category_names = doc.css('div[class="my-3"] a')
      create_category blog.id category_names if category_names.present?

      Rails.logger.info "=== title is #{title} === views: #{views} == created_at:#{created_at} author: #{author}"
      if created_at.include?('天') && created_at.present?
        temp_created_at =  created_at.split('天').first.to_i
        Rails.logger.info "=== temp_created_at #{temp_created_at}"
        created_at = Time.now - temp_created_at * 3600 * 24
        Rails.logger.info "=== created_at#{created_at}"
      end
      blog.update title: title, author: author, content: blog_content
      Rails.logger.info "===== in job, after update blog: #{blog.inspect}"
    end
  end
end



