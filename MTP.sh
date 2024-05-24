#!/bin/bash

# 生成随机的 32 位十六进制字符串作为 MTP_SECRET
generate_random_secret() {
    tr -dc 'a-f0-9' < /dev/urandom | head -c 32
}

# 提示用户输入 MTP_PORT 和 MTP_TAG
while true; do
    read -p "请输入 MTP_PORT (1-65535): " MTP_PORT
    if [[ $MTP_PORT -ge 1 && $MTP_PORT -le 65535 ]]; then
        break
    else
        echo "无效的端口号，请输入 1-65535 之间的端口号。"
    fi
done

# 生成或读取用户输入的 MTP_SECRET
read -p "是否生成随机的 MTP_SECRET？(Y/n): " generate_secret
if [[ $generate_secret =~ ^[Yy]$ || -z $generate_secret ]]; then
    MTP_SECRET=$(generate_random_secret)
    echo "生成的 MTP_SECRET 为: $MTP_SECRET"
else
    while true; do
        read -p "请输入 MTP_SECRET (32 个十六进制字符): " MTP_SECRET
        if [[ $MTP_SECRET =~ ^[0-9a-fA-F]{32}$ ]]; then
            break
        else
            echo "无效的 MTP_SECRET，请输入 32 个十六进制字符。"
        fi
    done
fi

# 设置默认的 MTP_TAG
MTP_TAG="f661069514b5fde9c00201a12a030c3e"

# 提示用户输入 MTP_TAG
read -p "请输入 MTP_TAG (32 个十六进制字符，默认为 $MTP_TAG): " tag_input
if [[ ! -z $tag_input && $tag_input =~ ^[0-9a-fA-F]{32}$ ]]; then
    MTP_TAG=$tag_input
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
      - MTP_TAG=${MTP_TAG}
      - MTP_DD_ONLY=t
      - MTP_TLS_ONLY=t
EOF

# 切换到部署目录并启动容器
cd ~/deploy/mtproto
docker-compose up -d

# 查看容器日志
docker-compose logs -f