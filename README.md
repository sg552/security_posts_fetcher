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
     `$ bundle exec ruby run.rb`
     2. 复制输出的命令，在命令行执行

### 抓取看雪的博客

步骤：

（1）安装playwright
    `$ npm init playwright@latest`
    选择JavaScript，然后一直回车即可。
    或者使用
    `$ yarn create playwright`
    选择JavaScript，然后一直回车即可。

（2）把以下两个脚本进行转移
     把看雪的脚本放在创建的tests目录下
    `cp scripts/kanxue.spec.js tests/`
    把浏览器的配置文件放在项目的根目录下
    `cp scripts/playwright.config.js .`

（3）把自动生成的example.spec.js文件进行删除
    `rm tests/example.spec.js`

（4）抓取抓取博客列表
    1. 修改run.rb 的内容，并运行
    `$ bundle exec ruby run.rb`
    2. 复制输出的命令，在命令行执


