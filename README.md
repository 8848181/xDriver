# xDriver
Bypass restrictive networks by tunneling SOCKS5 traffic through legitimate Google Drive API requests.


## 使用方法

ubuntu 一键安装命令。 

```bash
 bash <(curl -fsSL https://raw.githubusercontent.com/8848181/xDriver/main/install.sh)

```

 

## 配置文件中文注释版

因为仓库公开搜索结果能确认存在 `client_config.json.example` 和 `server_config.json.example`，但我这里拿不到它们的完整正文，所以我不能逐字段伪造“官方字段名+默认值”给你；那样反而容易误导你。 更稳妥的做法是：我先给你一份**中文注释模板版**，你把真实示例文件内容贴给我后，我再帮你逐字段精确改成最终版。 

### client 配置中文注释模板

```json
{
  "_comment_1": "这是客户端配置文件模板，用于帮助你阅读字段，不代表真实默认值。",
  "_comment_2": "客户端通常负责：本地监听、读取配置、建立会话、与远端传输层交互。",
  "_comment_3": "请以仓库中的 client_config.json.example 为准逐项对照。",

  "local_listen": "本地监听地址；通常是本机 IP 或 127.0.0.1 一类",
  "local_port": 0,
  "_comment_local": "这里一般表示客户端在本地监听的端口。若你看到 socks/listen/bind 一类字段，通常与此相关。",

  "remote_target": "远端目标地址或上游标识",
  "remote_port": 0,
  "_comment_remote": "如果示例里有 remote/target/upstream/destination 等字段，通常表示服务端最终连接目标或中继参数。",

  "drive_folder": "Google Drive 中用于交换数据的文件夹标识",
  "_comment_drive": "若示例中有 folder/folder_id/drive_id 等字段，通常与云端队列位置有关。",

  "poll_interval_ms": 0,
  "flush_interval_ms": 0,
  "_comment_timing": "如果项目通过轮询或批量写入传输数据，这类字段一般控制轮询频率、刷新间隔、清理节奏。",

  "session_timeout_sec": 0,
  "max_buffer_size": 0,
  "_comment_session": "若有 session/buffer/timeout 字段，通常决定会话生命周期和内存缓冲行为。",

  "tls_sni": "可选字段",
  "host_header": "可选字段",
  "_comment_http": "如果项目有伪装/封装到某种请求中的逻辑，这些字段可能与请求头、域名指示有关。",

  "log_level": "info",
  "_comment_log": "常见可选值可能有 debug/info/warn/error，具体以源码解析逻辑为准。"
}
```

### server 配置中文注释模板

```json
{
  "_comment_1": "这是服务端配置文件模板，用于帮助你理解结构，不代表真实默认值。",
  "_comment_2": "服务端通常负责：监控云端队列、取出消息、解码请求、桥接到真实 TCP 目标。",

  "listen_addr": "服务端监听地址或绑定地址",
  "listen_port": 0,
  "_comment_listen": "如果服务端本身需要监听某个端口，通常会有 listen/bind/address/port 字段。",

  "bridge_target": "实际转发目标地址",
  "bridge_port": 0,
  "_comment_bridge": "如果服务端负责桥接到真实目标，常见字段名可能是 target/upstream/destination/bridge。",

  "drive_folder": "与客户端共享的云端数据文件夹标识",
  "_comment_drive": "客户端和服务端若通过同一文件夹交换数据，这里通常要与另一端对应。",

  "poll_interval_ms": 0,
  "cleanup_interval_ms": 0,
  "_comment_timing": "常用于拉取消息、清理旧数据、处理过期会话。",

  "session_timeout_sec": 0,
  "max_sessions": 0,
  "_comment_session": "与会话数量、保活时间、资源回收相关。",

  "log_level": "info",
  "_comment_log": "日志级别字段通常会出现在 client/server 两端。"
}
```

## 更有效的做法

最有效的方式不是现在就手填配置，而是先把真实示例文件打印出来，再逐字段做中文映射，因为仓库公开信息只能确认这些示例文件存在，不能可靠展示它们完整字段内容。 你可以运行下面两条命令，把输出贴给我，我下一条就能给你做成**真正逐字段的中文注释版**。

```bash
cd ~/FlowDriver
sed -n '1,220p' client_config.json.example
sed -n '1,220p' server_config.json.example
```

## 我建议你下一步

你把这三样内容贴给我：

- `README.md` 前 200 行。[1]
- `client_config.json.example` 全文。[3]
- `server_config.json.example` 全文。[4]

 
