ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails'
require 'json'
require 'rubygems'
require 'httparty'


url = "https://xz.aliyun.com/"
Rails.logger.info "===#{url}"
headers = {
  'Host': 'xz.aliyun.com',
  'User-Agen':'Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Gecko/20100101 Firefox/106.0',
  'Accep': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
  'Accept-Languag': 'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
  'Accept-Encodin': 'gzip, deflate, br',
  'Connectio': 'keep-alive',
  'Cooki': 'cna=RVW0Gru+SF8CAbf+PUgM1No+; isg=BEdHq6Tn6Ie02G3OWVXr83B71fIRTBsuiRDlFRk0Y1b9iGdKIRyrfoVJKsjWe_Om; tfstk=caTFBI21CoU6APLNlNbyuurAAnQdZJdHZP5fxYv_MbRTH9sGixyRs921__NaEMf..; l=eBQbNcplL4_DN0VYBOfahurza77OSIOYYuPzaNbMiOCPOXfp5o2GW6y16bT9C31Vh6xvR35fl999BeYBYQd-nxvTkjOadJMmn; t=7a2881edec39e7fbff8a76ef506ff586; aliyun_choice=CN; currentRegionId=cn-hangzhou; login_aliyunid_pk=1387746726135732; aliyun_lang=zh; aliyun_country=CN; aliyun_site=CN; login_aliyunid_csrf=_csrf_tk_1133266830721115; _samesite_flag_=true; cookie2=1e17b3ab40e7857adf07c6459ec22c50; _tb_token_=586ee33685aed',
  'Upgrade-Insecure-Request': '1',
  'Sec-Fetch-Des': 'document',
  'Sec-Fetch-Mod': 'navigate',
  'Sec-Fetch-Sit': 'cross-site',
  'Sec-Fetch-Use': '?1'
}

response = HTTParty.get url, headers: headers #{"User-Agent" => APPLICATION_NAME}
puts "===response.body, #{response.body}"
puts "===response.code, #{response.code}"
puts "===response.headers #{response.headers}"

