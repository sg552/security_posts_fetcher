ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'open-uri'
require 'json'
require 'rubygems'
require 'httparty'
require 'nokogiri'

@logger = Logger.new("#{Rails.root}/log/get_the_details_of_a_blog_from_kanxue.log")
blogs = Blog.where('source_website = ?', 'kanxue')
if blogs.present?
  blogs.each do |blog|
    begin
      if blog.content.blank?
        @logger.info "== blog.inspect #{blog.inspect}"
        kanxue_url = "https://www.kanxue.com/"
        @logger.info "=== blog.blog_url : #{blog.blog_url}"
        headers = {
          'Host': 'bbs.pediy.com',
          'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Gecko/20100101 Firefox/106.0',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Cookie': '__jsluid_s=33efc98ca86b7d6d182f48c94a5f8824; __utma=181774708.684683680.1666926694.1667180033.1667204111.6; __utmz=181774708.1667180033.5.3.utmcsr=kanxue.com|utmccn=(referral)|utmcmd=referral|utmcct=/; _ga=GA1.2.1524884775.1666926736; __jsluid_h=213acb53f4c527a280d8e4207e0ba8e4; __utmc=181774708; bbs_sid=d33a89264e69595dbc6960aff7bc614e; __utmb=181774708.3.10.1667204111; __utmt=1',
          'Upgrade-Insecure-Requests': '1',
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': 'none',
          'Sec-Fetch-User': '?1'
        }
        if blog.blog_url.include? 'https:http'
          new_blog_url = blog.blog_url.sub("https:", '')
          @logger.info "== new_blog_url #{new_blog_url} blog.blog_url #{blog.blog_url}"
          blog.update blog_url: new_blog_url
          @logger.info "=== blog: #{blog.inspect}"
        elsif blog.blog_url.include? '//'
          blog.update blog_url: "https:#{blog.blog_url}"
          @logger.info "=== blog: #{blog.inspect}"
        end

        response = HTTParty.get blog.blog_url, :headers => headers
        #@logger.info "===response.code, #{response.code} === response.headers is #{response.headers}"
        doc = Nokogiri::HTML(response.body)
        #@logger.info "=== doc is #{doc} doc.class#{doc.class}"

        title = doc.css('h3').text.strip rescue ''
        author = doc.css('div[class="col"] span')[0].text.strip rescue ''
        created_at = doc.css('span[class="date text-grey ml-1"]').text.strip rescue ''
        #created_at = doc.css('div[class="col"] span')[1].text.strip rescue ''
        views = doc.css('div[class="col"] span')[2].text.to_i rescue ''

        to_get_content = doc.css('div[isfirst="1"]') rescue ''
        @logger.info "==  to_get_content is #{to_get_content}"
        images = doc.css("div[class='message '] img") rescue ''
        @logger.info "=== images is #{images}"
        blog_content = ''
        if images != ''
          images.to_ary.each do |image|
            @logger.info "=== image is #{image}"
            image_src = image.attr("src") rescue ''
            @logger.info "--- image_src is #{image_src} "
            image_name = image_src.sub('upload/attach/202210/', '') rescue ''
            @logger.info "=== image_src_sub is #{image_name}"
            `wget -cO - "https://bbs.pediy.com/#{image_src}" > "public/blog_images/#{image_name}"`
          end
        end
        blog_content = to_get_content.to_s.gsub("/upload/attach/202210/", "###MY_IMAGE_SITE###/images/")
        @logger.info "=== blog_content is #{blog_content}"

        doc.css('div[class="my-3"] a').each do |a|
          @logger.info "=== a is #{a}"
          category_name = a.text
          @logger.info "=== category_name is #{category_name}"
          category_local = Category.where('blog_id = ? and name = ?', blog.id, category_name).first
          @logger.info "=== category_local #{category_local.inspect}"
          if category_local.blank?
            Category.create blog_id: blog.id, name: category_name
          end
        end

        @logger.info "=== title is #{title} === views: #{views} == created_at:#{created_at} author: #{author}"
        if created_at.include?('天')
          temp_created_at =  created_at.split('天').first.to_i
          @logger.info "=== temp_created_at #{temp_created_at}"
          created_at = Time.now - temp_created_at * 3600 * 24
          @logger.info "=== created_at#{created_at}"
        end
        blog.update title: title, author: author, content: blog_content, views: views, created_at: created_at, source_website: 'kanxue'
        @logger.info "=====after update blog: #{blog.inspect}"
        @logger.info '===start 30'
        sleep 10
        @logger.info '==end 30'
      end
    rescue
      puts "=== hihi"
    end
  end
end
