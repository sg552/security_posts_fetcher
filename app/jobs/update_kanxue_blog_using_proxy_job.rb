class UpdateKanxueBlogUsingProxyJob < ApplicationJob
  retry_on CustomAppException # defaults to 3s wait, 5 attempts
  queue_as :default

#  Rails.logger = Logger.new("log/get_kanxue_blogs_using_proxy.log")

  retry_on(YetAnotherCustomAppException) do |job, error|
    ExceptionNotifier.caught(error)
  end

  def perform(blog)
    if blog.content.blank?
      Rails.logger.info "== blog.inspect #{blog.inspect}"
      kanxue_url = "https://www.kanxue.com/"
      Rails.logger.info "=== blog.blog_url : #{blog.blog_url}"

      blog_url = ''
      if blog.blog_url.include? 'artical'
        blog_url = blog.blog_url.sub('/', '').sub('/', '')
      else
        blog_url = blog.blog_url
      end

      proxy = Proxy.where('expiration_time > ?', Time.now).all.shuffle.first
      Rails.logger.info "==== proxy ip: #{proxy.external_ip rescue 'nil'}"
      command_to_get_blog_content= %Q{curl --socks5 #{proxy.ip}:#{proxy.port} #{blog_url}}
      Rails.logger.info "=== command_to_get_blog_content: #{command_to_get_blog_content}"
      result = `#{command_to_get_blog_content}`

      doc = Nokogiri::HTML(result)
      Rails.logger.info "=== doc is #{doc} doc.class#{doc.class}"

      title = doc.css('h3').text.strip rescue ''
      author = doc.css('div[class="col"] span')[0].text.strip rescue ''
      created_at = doc.css('span[class="date text-grey ml-1"]').text.strip rescue ''
      #created_at = doc.css('div[class="col"] span')[1].text.strip rescue ''
      views = doc.css('div[class="col"] span')[2].text.to_i rescue ''

      to_get_content = doc.css('div[isfirst="1"]') rescue ''
      Rails.logger.info "==  to_get_content is #{to_get_content}"
      images = doc.css("div[class='message '] img") rescue ''
      Rails.logger.info "=== images is #{images}"
      blog_content = ''
      if images != ''
        images.to_ary.each do |image|
          Rails.logger.info "=== image is #{image}"
          image_src = image.attr("src") rescue ''
          Rails.logger.info "--- image_src is #{image_src} "
          image_name = image_src.sub('upload/attach/202210/', '') rescue ''
          Rails.logger.info "=== image_src_sub is #{image_name}"
          `wget -cO - "https://bbs.pediy.com/#{image_src}" > "public/blog_images/#{image_name}"`
        end
      end
      blog_content = to_get_content.to_s.gsub("/upload/attach/202210/", "###MY_IMAGE_SITE###/images/")
      Rails.logger.info "=== blog_content is #{blog_content}"

      doc.css('div[class="my-3"] a').each do |a|
        Rails.logger.info "=== a is #{a}"
        category_name = a.text
        Rails.logger.info "=== category_name is #{category_name}"
        category_local = Category.where('blog_id = ? and name = ?', blog.id, category_name).first
        Rails.logger.info "=== category_local #{category_local.inspect}"
        if category_local.blank?
          Category.create blog_id: blog.id, name: category_name
        end
      end

      Rails.logger.info "=== title is #{title} === views: #{views} == created_at:#{created_at} author: #{author}"
      if created_at.include?('天')
        temp_created_at =  created_at.split('天').first.to_i
        Rails.logger.info "=== temp_created_at #{temp_created_at}"
        created_at = Time.now - temp_created_at * 3600 * 24
        Rails.logger.info "=== created_at#{created_at}"
      end
      blog.update title: title, author: author, content: blog_content, views: views, created_at: created_at, source_website: 'kanxue'
      Rails.logger.info "=====after update blog: #{blog.inspect}"
    end
  end
end
