ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'rubygems'
require 'httparty'
require 'date'
require 'json'

Rails.logger = Logger.new("log/create_proxies.log")

xianzhi_anquanjishu_column = ["安全技术", "众测渗透", "漏洞分析", "WEB安全", "二进制安全", "移动安全", "IoT安全", "企业安全", "区块链安全", "密码学", "CTF", "安全工具", "资源分享", "技术讨论"]
xianzhi_qingbao_column = ["情报", "先知情报"]
xianzhi_gonggao_column = ["社区公告"]

xianzhi_special_columns = xianzhi_anquanjishu_column + xianzhi_qingbao_column + xianzhi_gonggao_column
xianzhi_special_columns.each do |name|
  SpecialColumn.create name: name, source_website: 'xianzhi'
end

