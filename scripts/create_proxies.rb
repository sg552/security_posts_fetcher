ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'rubygems'
require 'httparty'
require 'date'
require 'json'

Rails.logger = Logger.new("log/create_proxies.log")

URL = "https://broker-api.lifeat.cn/user/app/broker/user/brokerUserDetail"
TIMEOUT = 10
NUMBER = 10

def get_proxy_token
  command_get_token = %Q{curl -d "user=bigbanana666&password=bigbanana888" https://dvapi.doveproxy.net/cmapi.php?rq=login}
  get_token = `#{command_get_token}`
  proxy_token = JSON.parse(get_token)['data']['token']
  Rails.logger.info "=========command_get_token #{command_get_token} ============proxy_token #{proxy_token}"
  return proxy_token
end

def get_ip_and_port
  proxy_token = get_proxy_token
  puts "proxy_token#{proxy_token}"
  city = ['in', 'id', 'ru', 'bd', 'za'].shuffle.first
  command_get_ip = %Q{curl -ipv4 -d "user=bigbanana666&token=#{proxy_token}&geo=#{city}&timeout=#{TIMEOUT}&num=#{NUMBER}" https://dvapi.doveproxy.net/cmapi.php?rq=distribute}
  puts "command_get_ip #{command_get_ip}"
  Rails.logger.info "========== command_get_ip #{command_get_ip}"
  get_ip = `#{command_get_ip}`
  temp_ip = get_ip.to_s.split("\r\n\r\n").last
  data = JSON.parse(temp_ip)['data'] rescue ''
  Rails.logger.info "==== proxy datas #{data}"
  return data
end

def create_proxy
  loop do
    datas = get_ip_and_port
    if datas.present?
      datas.each do |data|
        Proxy.create ip: data['ip'], port: data['port'], external_ip: data['d_ip'], expiration_time: (Time.now + TIMEOUT * 60) if data.present?
      end
    end
    Proxy.where('expiration_time < ?', Time.now).delete_all
    sleep TIMEOUT * 60 - 20
  end
end

create_proxy()

