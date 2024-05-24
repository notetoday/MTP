#!/bin/bash

# 提示用户输入 MTP_PORT, MTP_SECRET 和 MTP_TAG
read -p "请输入 MTP_PORT: " MTP_PORT
read -p "请输入 MTP_SECRET: " MTP_SECRET
read -p "请输入 MTP_TAG: " MTP_TAG

# 检查并安装 Docker
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，正在安装..."
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
else
    echo "Docker 已安装，跳过安装步骤。"
fi

# 检查并安装 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose 未安装，正在安装..."
    curl -L "https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 
    chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose 已安装，跳过安装步骤。"
fi

# 创建部署目录和 docker-compose.yml 文件
mkdir -p ~/deploy/mtproto
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
cd ~/deploy/mtproto
docker-compose up -d

# 查看容器日志
docker-compose logs -f