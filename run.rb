# 抓取先知社区的技术文章（目前只有18页）
#RAILS_ENV=development FROM=1 TO=10 URL=https://xz.aliyun.com/tab/1 setsid nohup bundle exec ruby scripts/get_xianzhi_blogs_using_proxy.rb &
#RAILS_ENV=development FROM=11 TO=18 URL=https://xz.aliyun.com/tab/1 setsid nohup bundle exec ruby scripts/get_xianzhi_blogs_using_proxy.rb &

(0..16).each do |i|
  # 使用代理抓取先知社区的博客列表和内容(社区板块，目前有177页)
  command = "RAILS_ENV=development FROM=#{i}1 TO=#{i+1}0 URL=https://xz.aliyun.com/tab/4 setsid nohup bundle exec ruby scripts/get_xianzhi_blogs_using_proxy.rb &"
  # 使用代理抓取看雪的博客列表
 # command = "RAILS_ENV=development PAGE_START=#{i}0 PAGE_END=#{i + 1}0 nohup bundle exec ruby scripts/get_kanxue_blogs_using_playwright.rb  &"
  puts command
end

