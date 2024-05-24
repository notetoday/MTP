#!/bin/bash

# 提示用户输入 MTP_PORT, MTP_SECRET 和 MTP_TAG
read -p "请输入 MTP_PORT: " MTP_PORT
read -p "请输入 MTP_SECRET: " MTP_SECRET
read -p "请输入 MTP_TAG: " MTP_TAG

# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh

# 安装 Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 
chmod +x /usr/local/bin/docker-compose

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
      - MTP_PORT=$MTP_PORT
      - MTP_SECRET=$MTP_SECRET
      - MTP_TAG=$MTP_TAG
      - MTP_DD_ONLY=t
      - MTP_TLS_ONLY=t
EOF

# 切换到部署目录并启动容器
cd ~/deploy/mtproto
docker-compose up -d

# 查看容器日志
docker-compose logs -f