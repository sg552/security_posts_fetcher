### 抓取先知的博客

步骤

（1）创建专栏的数据
    `$ bundle exec ruby scripts/create_special_column.rb`

（2）创建可以使用的代理
    `$ bundle exec ruby scripts/create_proxies.rb`

（3）创建保存图片的文件夹
    `mkdir public/blog_images/`

（4）使用代理抓取博客列表和详情页面
     1. 修改run.rb 的内容，并运行
     $ bundle exec ruby run.rb
     2. 复制输出的命令，在命令行执行

### 抓取看雪的博客
步骤：

（1）安装playwright
    `$ npm init playwright@latest`
    选择JavaScript，然后一直回车即可。
