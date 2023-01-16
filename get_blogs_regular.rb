# 抓取先知社区的技术文章（目前只有18页）
RAILS_ENV=development URL=https://xz.aliyun.com/tab/1 setsid nohup bundle exec ruby scripts/get_xianzhi_blogs_regular.rb &
RAILS_ENV=development URL=https://xz.aliyun.com/tab/4 setsid nohup bundle exec ruby scripts/get_xianzhi_blogs_regular.rb &


