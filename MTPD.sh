#!/bin/bash

# 调试部分：检查 lsb_release 命令是否可用
if ! command -v lsb_release &> /dev/null; then
    echo "无法检测系统类型，确保 'lsb_release' 命令已安装。"
    exit 1
fi

# 调试部分：输出 lsb_release 的信息
echo "检测系统信息："
lsb_release -a

# 检查系统是否是 Debian 11
distro=$(lsb_release -is)
version=$(lsb_release -rs)
if [[ "$distro" != "Debian" || "$version" != "11" ]]; then
    echo "此脚本仅支持 Debian 11 系统。"
    exit 1
fi

echo "系统检查通过，继续执行脚本。"

# 提示用户输入 MTP_PORT
while true; do
    read -p "请输入端口号 (1-65535): " MTP_PORT
    if [[ $MTP_PORT -ge 1 && $MTP_PORT -le 65535 ]]; then
        break
    else
        echo "无效的端口号，请输入 1-65535 之间的端口号。"
    fi
done

# 生成随机的 MTP_SECRET
while true; do
    read -p "请输入SECRET密钥（回车随机生成）: " input_secret
    if [[ -z $input_secret ]]; then
        MTP_SECRET=$(openssl rand -hex 16)
        echo "生成的随机密钥为: $MTP_SECRET"
        break
    elif [[ $input_secret =~ ^[0-9a-fA-F]{32}$ ]]; then
        MTP_SECRET=$input_secret
        break
    else
        echo "无效的 MTP_SECRET，请输入 32 个十六进制字符。"
    fi
done

MTP_TAG="f661069514b5fde9c00201a12a030c3e"
read -p "请输入TAG (回车使用默认值): " input_tag
if [[ ! -z $input_tag && $input_tag =~ ^[0-9a-fA-F]{32}$ ]]; then
    MTP_TAG=$input_tag
elif [[ ! -z $input_tag ]]; then
    echo "无效的 MTP_TAG，将使用默认值: $MTP_TAG"
fi

# 检查并安装 Docker
if ! command -v docker &> /dev/null; then
    echo "安装 Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
fi

# 检查并安装 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "安装 Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 
    chmod +x /usr/local/bin/docker-compose
fi

# 创建部署目录和 docker-compose.yml 文件
echo "创建部署目录和 docker-compose.yml 文件..."
mkdir -p ~/deploy/mtproto

# 生成 docker-compose.yml 文件
cat <<EOF > ~/deploy/mtproto/docker-compose.yml
version: "3.9"

services:
  mtproto:
    image: seriyps/mtproto-proxy
    container_name: mtproto
    restart: always
    network_mode: host
    environment:
      - MTP_PORT=${MTP_PORT}
      - MTP_SECRET=${MTP_SECRET}
      - MTP_TAG=${MTP_TAG}
      - MTP_DD_ONLY=t
      - MTP_TLS_ONLY=t
EOF

# 切换到部署目录并启动容器
echo "启动容器..."
cd ~/deploy/mtproto
docker-compose up -d

# 查看容器日志
echo "查看容器日志..."
docker-compose logs -f & wait