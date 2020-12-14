#!/bin/sh
## 用于https://github.com/mixool/dockershc项目安装运行dockerrun的脚本

FROM golang:alpine AS builder
# 修改源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# 安装相关环境依赖
RUN apk update && apk add --no-cache git bash wget curl
# 运行工作目录
WORKDIR /go/src/v2ray.com/core
# 克隆源码运行安装
RUN git clone --progress https://github.com/v2fly/v2ray-core.git . && \
    bash ./release/user-package.sh nosource noconf codename=$(git describe --tags) buildname=docker-fly abpathtgz=/tmp/v2ray.tgz
# 拷贝v2ray二进制文件至临时目录
COPY --from=builder /tmp/v2ray.tgz /tmp

# 授予文件权限
RUN set -ex && \
    apk --no-cache add tor ca-certificates && \
    mkdir -p /usr/bin/v2ray && \
    tar xvfz /tmp/v2ray.tgz -C /usr/bin/v2ray && \
    rm -rf /tmp/v2ray.tgz /usr/bin/v2ray/*.sig /usr/bin/v2ray/doc /usr/bin/v2ray/*.json /usr/bin/v2ray/*.dat /usr/bin/v2ray/sys* && \
    chmod +x /usr/bin/v2ray/v2ctl && \
    chmod +x /usr/bin/v2ray/v2ray

if [[ ! -f "/workerone" ]]; then
    # install and rename
#     wget -qO- https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip | busybox unzip - >/dev/null 2>&1
#     git clone --progress https://github.com/v2fly/v2ray-core.git . && \
#     bash ./release/user-package.sh nosource noconf codename=$(git describe --tags) buildname=docker-fly abpathtgz=/tmp/v2ray.tgz
#     sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
#     apk update
    mv /usr/bin/v2ray/v2ray /workerone
    cat <<EOF >/config.json
{
    "inbounds": 
    [
        {
            "port": "3000","listen": "0.0.0.0","protocol": "vless",
            "settings": {"clients": [{"id": "86892e01-cf95-45e1-82a8-9554cdd3bcc3"}],"decryption": "none"},
            "streamSettings": {"network": "ws","wsSettings": {"path": "/website"}}
        }
    ],
    "outbounds": 
    [
        {"protocol": "freedom","tag": "direct","settings": {}},
        {"protocol": "blackhole","tag": "blocked","settings": {}}
    ],
    "routing": 
    {
        "rules": 
        [
            {"type": "field","outboundTag": "blocked","ip": ["geoip:private"]},
            {"type": "field","outboundTag": "block","protocol": ["bittorrent"]},
            {"type": "field","outboundTag": "blocked","domain": ["geosite:category-ads-all"]}
        ]
    }
}
EOF
else
    # start 
    /workerone -config /config.json >/dev/null 2>&1
fi
