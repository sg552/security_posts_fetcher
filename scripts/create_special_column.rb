ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'rubygems'
require 'httparty'
require 'date'
require 'json'

Rails.logger = Logger.new("log/create_proxies.log")

xianzhi_shequ_column = ["社区板块"]
xianzhi_gonggao_column = ["社区公告"]
xianzhi_jishu_wenzhang_column = ["技术文章"," 翻译文章"]

xianzhi_special_columns = xianzhi_+ xianzhi_gonggao_column + xianzhi_jishu_wenzhang_column
xianzhi_special_columns.each do |name|
  SpecialColumn.create name: name, source_website: 'xianzhi'
end

