#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="FlowDriver"
REPO_URL="https://github.com/NullLatency/FlowDriver.git"
INSTALL_DIR_DEFAULT="$HOME/FlowDriver"
GO_VERSION_DEFAULT="1.24.2"

color() {
  local code="$1"; shift
  printf "\033[%sm%s\033[0m\n" "$code" "$*"
}

info()  { color "1;34" "[INFO] $*"; }
ok()    { color "1;32" "[ OK ] $*"; }
warn()  { color "1;33" "[WARN] $*"; }
error() { color "1;31" "[ERR ] $*"; }

ask() {
  local prompt="$1"
  local default="${2:-}"
  local value
  if [[ -n "$default" ]]; then
    read -r -p "$prompt [$default]: " value || true
    echo "${value:-$default}"
  else
    read -r -p "$prompt: " value || true
    echo "$value"
  fi
}

pause() {
  read -r -p "按回车继续..." _ || true
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

ensure_ubuntu() {
  if [[ ! -f /etc/os-release ]]; then
    error "无法识别系统版本，缺少 /etc/os-release"
    exit 1
  fi
  . /etc/os-release
  if [[ "${ID:-}" != "ubuntu" && "${ID_LIKE:-}" != *"ubuntu"* ]]; then
    warn "检测到当前系统不是标准 Ubuntu，脚本仍可尝试继续，但未保证完全兼容。"
  else
    ok "检测到系统：${PRETTY_NAME:-Ubuntu}"
  fi
}

install_base_deps() {
  info "安装基础依赖..."
  sudo apt update
  sudo apt install -y git curl ca-certificates build-essential tar
  ok "基础依赖已安装"
}

install_go() {
  local go_version="$1"

  if need_cmd go; then
    local current
    current="$(go version 2>/dev/null || true)"
    ok "检测到 Go：$current"
    return 0
  fi

  info "未检测到 Go，开始安装 Go ${go_version} ..."
  cd /tmp
  curl -LO "https://go.dev/dl/go${go_version}.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go${go_version}.linux-amd64.tar.gz"

  if ! grep -q '/usr/local/go/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"
  fi
  export PATH="$PATH:/usr/local/go/bin"

  ok "Go 安装完成：$(go version)"
}

clone_or_update_repo() {
  local install_dir="$1"

  if [[ -d "$install_dir/.git" ]]; then
    info "检测到已有仓库，执行更新..."
    git -C "$install_dir" pull --ff-only
    ok "仓库已更新"
  else
    info "开始克隆仓库到：$install_dir"
    git clone "$REPO_URL" "$install_dir"
    ok "仓库克隆完成"
  fi
}

build_project() {
  local install_dir="$1"
  cd "$install_dir"

  info "下载 Go 依赖..."
  go mod tidy || warn "go mod tidy 执行失败，请稍后手动检查"

  mkdir -p build

  if [[ -d cmd ]]; then
    info "检测到 cmd/ 目录，尝试逐个编译..."
    local built_any=0
    shopt -s nullglob
    for d in cmd/*; do
      if [[ -d "$d" ]]; then
        local name
        name="$(basename "$d")"
        info "编译子程序：$name"
        if go build -o "build/$name" "./cmd/$name"; then
          ok "编译成功：build/$name"
          built_any=1
        else
          warn "编译失败：$name（不影响脚本继续执行）"
        fi
      fi
    done
    shopt -u nullglob

    if [[ "$built_any" -eq 0 ]]; then
      warn "没有成功编译出 cmd 下的程序，尝试编译主程序..."
      go build -o build/flowdriver . || warn "主程序编译也失败，请手动检查源码和依赖"
    fi
  else
    warn "未发现 cmd/ 目录，尝试编译主程序..."
    go build -o build/flowdriver . || warn "主程序编译失败，请手动检查"
  fi
}

prepare_configs() {
  local install_dir="$1"
  cd "$install_dir"

  info "复制示例配置..."
  [[ -f client_config.json.example ]] && cp -n client_config.json.example client_config.json || true
  [[ -f server_config.json.example ]] && cp -n server_config.json.example server_config.json || true

  cat > CONFIG_中文说明.md <<'EOF'
# FlowDriver 配置文件中文说明（学习版）

> 这份说明文件用于“帮助阅读配置结构”，不是可直接上线的代理配置。

## 你现在应该看到的文件

- `client_config.json.example`：客户端示例配置
- `server_config.json.example`：服务端示例配置
- `client_config.json`：由脚本复制出的本地学习模板
- `server_config.json`：由脚本复制出的本地学习模板

## 推荐阅读方式

1. 先打开 `README.md`
2. 再看 `client_config.json.example`
3. 再看 `server_config.json.example`
4. 最后结合 `cmd/` 目录源码，寻找每个字段在哪里被读取

## 字段理解方法

对于每个 JSON 字段，请按下面方式做笔记：

- 字段名：
- 可能类型：字符串 / 数字 / 布尔 / 数组 / 对象
- 作用猜测：
- 是否客户端专用：
- 是否服务端专用：
- 是否与 Google 凭证相关：
- 是否与本地监听有关：
- 是否与远端目标有关：
- 对应源码位置：

## 注意

- 不要直接照抄网上参数运行。
- 不要在公网环境测试未知配置。
- 优先在虚拟机、隔离网络、测试账号中学习。
EOF

  ok "配置模板与中文说明文件已准备完成"
}

show_tree_hint() {
  local install_dir="$1"
  cat <<EOF

================ 处理完成 ================

项目目录：
  $install_dir

建议你下一步执行：

  cd "$install_dir"
  ls
  ls cmd
  sed -n '1,200p' README.md
  sed -n '1,200p' client_config.json.example
  sed -n '1,200p' server_config.json.example

如需查看编译结果：
  ls -lah "$install_dir/build"

注意：
- 本脚本不会自动运行 client/server
- 本脚本不会写入可直接上线的代理命令
- 你现在得到的是“安全学习环境”

==========================================
EOF
}

main() {
  clear || true
  echo "=============================================="
  echo " FlowDriver 安全版交互安装脚本（Ubuntu 学习版）"
  echo "=============================================="
  echo
  echo "本脚本仅用于："
  echo "  1) 安装编译环境"
  echo "  2) 拉取源码"
  echo "  3) 尝试构建二进制"
  echo "  4) 复制示例配置"
  echo "  5) 生成中文说明文件"
  echo
  echo "不会自动启动任何 client/server。"
  echo

  ensure_ubuntu
  pause

  local install_dir
  install_dir="$(ask "请输入安装目录" "$INSTALL_DIR_DEFAULT")"

  local go_version
  go_version="$(ask "请输入要安装的 Go 版本" "$GO_VERSION_DEFAULT")"

  echo
  info "安装目录：$install_dir"
  info "Go 版本：$go_version"
  echo

  local confirm
  confirm="$(ask "确认开始执行？(yes/no)" "yes")"
  if [[ "$confirm" != "yes" ]]; then
    warn "用户取消执行"
    exit 0
  fi

  install_base_deps
  install_go "$go_version"
  clone_or_update_repo "$install_dir"
  build_project "$install_dir"
  prepare_configs "$install_dir"
  show_tree_hint "$install_dir"

  ok "全部步骤执行完成"
}

main "$@"
