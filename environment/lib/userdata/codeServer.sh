#!/bin/bash
# cloud-init は root で実行されるが HOME が未設定のため、$HOME を参照する
# インストーラ（code-server / Kiro CLI 等）が "HOME: parameter not set" で失敗する。
# 明示的に HOME を設定し、ダウンロード物の置き場所も固定する。
export HOME=/root
cd /root

sudo apt update
sudo apt install -y pwgen jq curl zip unzip

# AWS CLI v2のインストール
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/

# Dockerのインストール
sudo apt install -y docker.io
sudo usermod -aG docker ubuntu
sudo systemctl enable --now docker

# AWS SAM CLIのインストール
wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
unzip aws-sam-cli-linux-x86_64.zip -d sam-installation
sudo ./sam-installation/install
rm -rf aws-sam-cli-linux-x86_64.zip sam-installation/

## Kiro CLI のインストール
curl -fsSL https://cli.kiro.dev/install | bash
sudo dpkg -i kiro-cli.deb
sudo apt-get install -f

# Python 3.14のインストール（deadsnakes PPAから最新版を導入）
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.14 python3.14-venv python3.14-dev

# pip（3.14用）のインストール
curl -fsSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
sudo python3.14 /tmp/get-pip.py
rm -f /tmp/get-pip.py

# pythonコマンドでPython 3.14を実行できるようにする
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.14 1

# Node.jsのインストール
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt update
sudo apt install -y nodejs

# code-server のインストール（公式インストールスクリプト）
# 版数解決・アーキ判定・systemd ユニット(code-server@)登録まで自動で行うため、
# GitHub API + 手動 .deb 取得よりも堅牢（API のレート制限/非JSON応答で失敗しない）
curl -fsSL https://code-server.dev/install.sh | sh

# セットアップ
mkdir -p /home/ubuntu/.config/code-server/
PASSWORD=$(pwgen -s -n -c 32 1)
# cert: false … TLS は前段の CloudFront で終端するため code-server は HTTP で待ち受ける
sudo bash -c "cat > /home/ubuntu/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:50443
auth: password
password: ${PASSWORD}
cert: false
EOF"
sudo chown -R ubuntu:ubuntu /home/ubuntu/.config

# パスワードをSSM Parameter Storeに保存
# IMDSv2を使用してインスタンスIDを取得
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

# SSMパラメータを作成
aws ssm put-parameter --name "/workshop/code-server/${INSTANCE_ID}/password" --value "${PASSWORD}" --type "SecureString" --description "Code-server password for instance ${INSTANCE_ID}" --region ${REGION} --overwrite

# 参加者向け README を /home/ubuntu 直下に作成
cat > /home/ubuntu/README.md << 'EOF'
# README

## 手順書のダウンロード

> git clone https://github.com/hamazlabo/workshop-for-kiro.git

## Kiro が起動しない場合

```bash
curl -fsSL https://cli.kiro.dev/install | bash
sudo dpkg -i kiro-cli.deb
sudo apt-get install -f
export PATH="$HOME/.local/bin:$PATH"
```
EOF
chown ubuntu:ubuntu /home/ubuntu/README.md

# サービス開始
sudo systemctl enable --now code-server@ubuntu