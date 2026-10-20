# SpringCloud 分布式微服务学习 Demo

> 基于 **Spring Cloud + Nacos + Gateway + OpenFeign + Docker Compose** 的微服务入门案例：用户服务、订单服务、网关三个微服务，通过 Nacos 完成服务注册与发现，订单服务使用 Feign 远程调用用户服务，网关统一入口并做鉴权，最后用 Docker Compose 一键部署整套集群。

![Java](https://img.shields.io/badge/Java-1.8-orange)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-2.3.9-brightgreen)
![Spring Cloud](https://img.shields.io/badge/Spring%20Cloud-Hoxton.SR10-blue)
![Spring Cloud Alibaba](https://img.shields.io/badge/Spring%20Cloud%20Alibaba-2.2.5-ff6a00)
![Nacos](https://img.shields.io/badge/Nacos-2.2.0-1e90ff)
![Docker](https://img.shields.io/badge/Docker%20Compose-3.2-2496ED)

## 目录

- [项目简介](#项目简介)
- [技术栈](#技术栈)
- [系统架构](#系统架构)
- [项目结构](#项目结构)
- [快速开始（Docker Compose 一键部署）](#快速开始docker-compose-一键部署)
- [接口访问](#接口访问)
- [Nacos 配置中心（可选）](#nacos-配置中心可选)
- [本地开发运行](#本地开发运行)
- [重新打包 app.jar](#重新打包-appjar)
- [知识点速览](#知识点速览)
- [常见问题](#常见问题)
- [声明](#声明)

## 项目简介

项目包含 3 个业务微服务、1 个公共 Feign 模块和 1 个 Eureka 学习模块：

| 模块 | 端口 | 说明 |
| --- | --- | --- |
| `gateway` | `10010` | 网关服务：统一入口，按路径路由到用户 / 订单服务，全局过滤器做简单鉴权 |
| `user-service` | `8081` | 用户服务：根据 id 查询用户，数据库 `cloud_user`，支持从 Nacos 读取配置 |
| `order-service` | `8088` | 订单服务：根据 id 查询订单，并通过 Feign 调用用户服务，返回“订单 + 用户”，数据库 `cloud_order` |
| `feign-api` | - | 公共模块：抽取 `UserClient`、`User`、Feign 默认配置，供订单服务引用 |
| `eureka-server` | `10086` | Eureka 注册中心（学习对比用；当前部署流程使用 Nacos，未纳入 Docker Compose） |

## 技术栈

| 类别 | 技术 |
| --- | --- |
| 基础框架 | Spring Boot 2.3.9.RELEASE、Java 8、Maven 多模块 |
| 微服务套件 | Spring Cloud Hoxton.SR10、Spring Cloud Alibaba 2.2.5.RELEASE |
| 注册 / 配置中心 | Nacos 2.2.0（standalone 模式） |
| 服务调用 | OpenFeign（+ HttpClient 连接池）、Ribbon（`NacosRule` 负载均衡、饥饿加载） |
| 网关 | Spring Cloud Gateway（路由、默认过滤器、全局过滤器） |
| 持久层 | MyBatis（`mybatis-spring-boot-starter` 2.1.1）、MySQL 5.7 |
| 部署 | Docker、Docker Compose |

## 系统架构

```
                     ┌──────────────────────────────┐
  客户端 ──────────?  │   gateway :10010             │
 ?authorization=admin │  ① 全局过滤器：校验 authorization │
                     │  ② 路由：/user/**  /order/**    │
                     │  ③ 默认过滤器：添加请求头 Truth   │
                     └──────┬───────────────┬────────┘
                            │ lb://         │ lb://
                   ┌────────▼──────┐  ┌─────▼────────────┐
                   │ userservice   │?─┤ orderservice     │
                   │   :8081       │  │   :8088          │
                   │               │  │ Feign 调用用户服务 │
                   └───┬───────────┘  └───┬──────────────┘
                       │                  │
          注册 / 读取配置 │                  │ 注册
                       ▼                  ▼
                  ┌──────────┐      ┌───────────────────┐
                  │  Nacos   │      │   MySQL :3306     │
                  │  :8848   │      │ cloud_user        │
                  └──────────┘      │ cloud_order       │
                                    └───────────────────┘
```

**一次订单查询的调用链：**

`GET /order/102?authorization=admin` → 网关鉴权通过 → 路由到 `orderservice` → 查询订单表 → 通过 Feign 调用 `userservice` 查询下单用户 → 组装后返回订单（含 user 信息）。

## 项目结构

```
.
├── cloud-demo部署文件                  # Docker 部署相关文件
│   ├── docker-compose.yml             # 一键部署：nacos、mysql、userservice、orderservice、gateway
│   ├── 项目运行说明.txt                 # 作者的运行笔记
│   ├── gateway/
│   │   ├── Dockerfile
│   │   └── app.jar                    # gateway 打包产物
│   ├── user-service/
│   │   ├── Dockerfile
│   │   └── app.jar                    # user-service 打包产物
│   ├── order-service/
│   │   ├── Dockerfile
│   │   └── app.jar                    # order-service 打包产物
│   └── mysql/
│       ├── conf/hmy.cnf               # MySQL 配置（字符集等）
│       ├── cloud_user.sql             # 用户库脚本（tb_user，6 条数据）
│       └── cloud_order.sql            # 订单库脚本（tb_order，8 条数据）
└── cloud-demo项目源码                  # Maven 多模块源码
    ├── pom.xml                        # 父工程：统一管理 Spring Cloud / Alibaba 版本
    ├── gateway/                       # 网关（AuthorizeFilter 全局鉴权）
    ├── user-service/                  # 用户服务
    ├── order-service/                 # 订单服务
    ├── feign-api/                     # Feign 公共模块
    └── eureka-server/                 # Eureka 注册中心（学习模块）
```

## 快速开始（Docker Compose 一键部署）

### 1. 环境要求

- Docker 20+ 与 Docker Compose
- 空闲端口：`8848`（Nacos）、`3307`（MySQL）、`10010`（网关）

### 2. 获取项目

```bash
git clone <你的仓库地址>
cd <仓库目录>/cloud-demo部署文件
```

> 三个服务目录下已提供打包好的 `app.jar`，Dockerfile 会直接把它复制进镜像，无需本地先编译。如需修改代码后重新打包，见 [重新打包 app.jar](#重新打包-appjar)。

### 3. 启动容器

```bash
docker-compose up -d
```

`docker-compose.yml` 会启动 5 个容器：

| 服务名 | 镜像 / 构建 | 对外端口 |
| --- | --- | --- |
| `nacos` | `nacos/nacos-server:v2.2.0`（standalone） | `8848` |
| `mysql` | `mysql:5.7.25`（root 密码 `123`） | `3307 → 3306` |
| `userservice` | 使用 `user-service/Dockerfile` 构建 | - |
| `orderservice` | 使用 `order-service/Dockerfile` 构建 | - |
| `gateway` | 使用 `gateway/Dockerfile` 构建 | `10010` |

### 4. 初始化数据库

MySQL 容器启动后，数据库是空的。脚本里只有建表和数据、没有建库语句，所以先建库再导入：

```bash
# 建库
docker-compose exec mysql mysql -uroot -p123 \
  -e "CREATE DATABASE IF NOT EXISTS cloud_user DEFAULT CHARSET utf8; CREATE DATABASE IF NOT EXISTS cloud_order DEFAULT CHARSET utf8;"

# 导入数据
docker exec -i $(docker-compose ps -q mysql) mysql -uroot -p123 --default-character-set=utf8 cloud_user  < mysql/cloud_user.sql
docker exec -i $(docker-compose ps -q mysql) mysql -uroot -p123 --default-character-set=utf8 cloud_order < mysql/cloud_order.sql
```

也可以用 Navicat / DBeaver 连接 `127.0.0.1:3307`（账号 `root`，密码 `123`）手动创建数据库并执行 SQL。

### 5. 重启微服务（解决启动顺序问题）

Nacos 启动较慢，业务微服务可能比 Nacos 先启动而注册失败，此时重启微服务容器即可：

```bash
docker-compose restart userservice orderservice gateway
```

### 6. 验证

- Nacos 控制台：<http://localhost:8848/nacos>（默认账号 / 密码：`nacos` / `nacos`）。在「服务管理 → 服务列表」中应能看到 `userservice`、`orderservice`、`gateway`
- 接口访问见下一节

### 常用运维命令

```bash
docker-compose up -d                         # 一键启动所有容器
docker-compose ps                            # 查看容器状态
docker-compose logs -f                       # 查看所有容器日志
docker-compose logs -f userservice           # 查看指定容器日志
docker-compose restart userservice orderservice gateway   # 重启微服务
docker-compose down                          # 停止并删除容器
```

## 接口访问

所有请求都通过网关 `10010` 端口访问，且**必须携带参数 `authorization=admin`**，否则会返回 `401`。

| 说明 | 地址 |
| --- | --- |
| 查询用户 | <http://localhost:10010/user/2?authorization=admin> |
| 查询订单（含用户信息） | <http://localhost:10010/order/102?authorization=admin> |

> 使用 Docker 部署在其他机器或虚拟机上时，把 `localhost` 换成对应机器的 IP。

初始化数据：用户 id 为 `1 ~ 6`，订单 id 为 `101 ~ 108`。

订单 `102` 对应用户 `2`，返回的数据结构大致如下：

```json
{
  "id": 102,
  "price": 209900,
  "name": "雅迪 yadea 新国标电动车",
  "num": 1,
  "userId": 2,
  "user": {
    "id": 2,
    "username": "文二狗",
    "address": "陕西省西安市"
  }
}
```

| 场景 | 结果 |
| --- | --- |
| 不带 `authorization` 或值不是 `admin` | `401 Unauthorized`（被网关全局过滤器拦截） |
| 带 `authorization=admin` | 正常返回 |

## Nacos 配置中心（可选）

`user-service` 在 `bootstrap.yml` 中接入了 Nacos 配置中心（环境 `dev`，格式 `yaml`），会读取 Data ID 为 `userservice-dev.yaml` 的配置。

如果要体验 `/user/now`、`/user/prop` 这两个演示接口，需要在 Nacos 控制台「配置管理 → 配置列表」新建配置：

| 项 | 值 |
| --- | --- |
| Data ID | `userservice-dev.yaml` |
| Group | `DEFAULT_GROUP` |
| 配置格式 | `YAML` |

配置内容（示例）：

```yaml
pattern:
  dateformat: yyyy-MM-dd HH:mm:ss
```

之后通过网关访问：

- <http://localhost:10010/user/now?authorization=admin>：按配置的日期格式返回当前时间
- <http://localhost:10010/user/prop?authorization=admin>：返回读取到的 `pattern` 配置

> 不配置不影响 `/user/{id}` 和 `/order/{id}` 的正常使用，只有 `/user/now` 依赖 `pattern.dateformat`。

## 本地开发运行

源码中的 `application.yml` 是按 **Docker Compose 网络**配置的：

- Nacos 地址：`nacos:8848`
- MySQL 地址：`mysql:3306`

如果想在 IDEA 中直接启动各服务，需要改成本机可访问的地址：

| 配置 | Docker 环境（默认） | 本地 IDEA 运行 |
| --- | --- | --- |
| Nacos `server-addr` | `nacos:8848` | `127.0.0.1:8848` |
| MySQL `url` | `jdbc:mysql://mysql:3306/...` | `jdbc:mysql://127.0.0.1:3307/...`（Compose 映射端口） |

涉及文件：

- `user-service/src/main/resources/bootstrap.yml`、`application.yml`
- `order-service/src/main/resources/application.yml`
- `gateway/src/main/resources/application.yml`

启动顺序：先启动 Nacos 和 MySQL（可只运行 `docker-compose up -d nacos mysql`），再启动 `user-service` → `order-service` → `gateway`。

## 重新打包 app.jar

三个服务的 `pom.xml` 都配置了 `<finalName>app</finalName>`，打包后产物为 `target/app.jar`，与 Dockerfile 中的 `COPY ./app.jar /tmp/app.jar` 对应。

```bash
cd cloud-demo项目源码
mvn clean package -DskipTests

# 把各模块生成的 app.jar 复制到对应的部署目录
cp gateway/target/app.jar       ../cloud-demo部署文件/gateway/app.jar
cp user-service/target/app.jar  ../cloud-demo部署文件/user-service/app.jar
cp order-service/target/app.jar ../cloud-demo部署文件/order-service/app.jar

# 重新构建镜像并启动
cd ../cloud-demo部署文件
docker-compose up -d --build
```

Dockerfile 内容（三个服务相同）：

```dockerfile
FROM eclipse-temurin:8-jre-alpine
COPY ./app.jar /tmp/app.jar
ENTRYPOINT java -jar /tmp/app.jar
```

## 知识点速览

| 知识点 | 位置 |
| --- | --- |
| Nacos 服务注册与发现 | 各服务 `spring.cloud.nacos.server-addr` |
| Nacos 配置中心 | `user-service/bootstrap.yml`、`PatternProperties`（`@ConfigurationProperties`） |
| Feign 远程调用 | `feign-api` 的 `UserClient`、`order-service` 的 `OrderService` |
| Feign 优化 | 日志级别 `DefaultFeignConfiguration`；`feign.httpclient` 连接池配置 |
| 抽取 Feign 公共模块 | `feign-api` 模块，`@EnableFeignClients(clients = UserClient.class, ...)` |
| Ribbon 负载均衡 | `order-service/application.yml`：`NacosRule`、饥饿加载；`OrderApplication` 中 `@LoadBalanced` 的 `RestTemplate`（Feign 之前的调用方式，`OrderService` 注释代码中保留了对比） |
| Gateway 路由 | `gateway/application.yml`：`lb://userservice`、`Path=/user/**` |
| Gateway 默认过滤器 | `AddRequestHeader=Truth,...`，`UserController` 中通过 `@RequestHeader("Truth")` 接收 |
| Gateway 全局过滤器 | `AuthorizeFilter`（`GlobalFilter` + `Ordered`），校验 `authorization=admin` |
| Docker 部署微服务 | `docker-compose.yml` + 各服务 `Dockerfile` |

## 常见问题

**Q：`docker-compose up` 构建镜像时报 `java:8-alpine` 拉取失败？**
`java:8-alpine` 镜像已不再维护。本项目的 Dockerfile 已改为 `eclipse-temurin:8-jre-alpine`。

**Q：Nacos 使用最新版镜像无法正常运行？**
最新版 Nacos 与本项目使用的 Spring Cloud Alibaba 2.2.5 不兼容，请使用 `nacos/nacos-server:v2.2.0`（`docker-compose.yml` 中已指定）。

**Q：服务启动了，但 Nacos 服务列表里没有微服务 / 访问报 503？**
一般是微服务比 Nacos 先启动。执行 `docker-compose restart userservice orderservice gateway`，并通过 `docker-compose logs -f userservice` 查看日志确认注册成功。

**Q：访问接口返回 401？**
请求必须带 `?authorization=admin`，这是网关 `AuthorizeFilter` 的校验规则。

**Q：访问订单 / 用户接口返回 500？**
通常是数据库还没初始化：确认已建库 `cloud_user`、`cloud_order` 并导入 SQL；用 `docker-compose logs -f orderservice` 查看具体报错。

**Q：MySQL 数据在哪里？**
`docker-compose.yml` 把数据目录挂载到了 `./mysql/data`，首次启动后会自动生成。为避免仓库体积过大，该目录不会提交到 GitHub，仓库里只保留了 SQL 脚本，需要自行导入。

**Q：日志里出现 Eureka 连接失败的提示？**
`user-service`、`order-service` 的依赖中同时包含了 Eureka Client（学习对比 Eureka 与 Nacos 时遗留），而项目实际使用 Nacos 做注册发现，此类日志一般不影响运行。

## 声明

本项目为 Spring Cloud 微服务**学习与交流**用途，请勿用于商业用途。
