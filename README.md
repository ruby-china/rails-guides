= Rails Guide 中文翻译

== 构建（基于 Docker）

为了管理依赖，建议使用 Docker。

=== 安装 Docker

https://www.docker.com/

=== 构建镜像

```bash
$ docker build -t rails-guides .
```

=== 构建

```bash
$ docker run -it -v $(pwd):/app rails-guides rake guides:generate:html
$ docker run -it -v $(pwd):/app rails-guides rake guides:generate:kindle
```

== 发布

另外 clone 一份 repo，checkout 到 `gh-pages` 分支，将 HTML 版内容拷贝进去，commit，push。

Kindle 版通过 GitHub Release 发布。
