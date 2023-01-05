##RAILS_ENV=development FROM=7 TO=18 PAGE_TYPE=shequ URL=https://xz.aliyun.com/tab/1 bundle exec ruby scripts/get_xianzget_xianzhi_blogs_using_proxy_blogs_using_proxy.rb

(0..16).each do |i|
  command = "RAILS_ENV=development FROM=#{i}1 TO=#{i+1}0 URL=https://xz.aliyun.com/tab/4 setsid nohup bundle exec ruby scripts/get_xianzhi_blogs_using_proxy.rb &"
  puts command
end

