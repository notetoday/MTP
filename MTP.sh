#!/bin/bash

# 提示用户输入 MTP_PORT, MTP_SECRET 和 MTP_TAG
while true; do
    read -p "请输入 MTP_PORT (1-65535): " MTP_PORT
    if [[ $MTP_PORT -ge 1 && $MTP_PORT -le 65535 ]]; then
        break
    else
        echo "无效的端口号，请输入 1-65535 之间的端口号。"
    fi
done

while true; do
    read -p "请输入 MTP_SECRET (32 个十六进制字符): " MTP_SECRET
    if [[ $MTP_SECRET =~ ^[0-9a-fA-F]{32}$ ]]; then
        break
    else
        echo "无效的 MTP_SECRET，请输入 32 个十六进制字符。"
    fi
done

read -p "请输入 MTP_TAG (32 个十六进制字符, 可选): " MTP_TAG
if [[ ! $MTP_TAG =~ ^[0-9a-fA-F]{32}$ ]]; then
    MTP_TAG=""
    echo "MTP_TAG 留空"
fi

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
EOF

# 如果 MTP_TAG 不为空，则添加到文件中
if [[ -n $MTP_TAG ]]; then
    echo "      - MTP_TAG=${MTP_TAG}" >> ~/deploy/mtproto/docker-compose.yml
fi

# 继续添加其余的环境变量
cat <<EOF >> ~/deploy/mtproto/docker-compose.yml
      - MTP_DD_ONLY=t
      - MTP_TLS_ONLY=t
EOF

# 切换到部署目录并启动容器
cd ~/deploy/mtproto
docker-compose up -d

# 查看容器日志
docker-compose logs -f