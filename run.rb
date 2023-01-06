##RAILS_ENV=development FROM=7 TO=18 PAGE_TYPE=shequ URL=https://xz.aliyun.com/tab/1 bundle exec ruby scripts/get_xianzget_xianzhi_blogs_using_proxy_blogs_using_proxy.rb

(0..16).each do |i|
  # 使用代理抓取先知社区的博客列表和内容
  #command = "RAILS_ENV=development FROM=#{i}1 TO=#{i+1}0 URL=https://xz.aliyun.com/tab/4 setsid nohup bundle exec ruby scripts/get_xianzhi_blogs_using_proxy.rb &"
  # 使用代理抓取看雪的博客列表
  command = "RAILS_ENV=development PAGE_START=#{i}0 PAGE_END=#{i + 1}0 nohup bundle exec ruby scripts/get_kanxue_blogs_using_playwright.rb  &"
  puts command
end

