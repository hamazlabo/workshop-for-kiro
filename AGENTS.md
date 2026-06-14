# AGENTS

このリポジトリはワークショップの作業用リポジトリです。
参加者は AWS 上にデプロイされた **code-server**（ブラウザ版 VS Code）からこのリポジトリ直下をワークスペースとして開き、その中で開発を行います。

このファイルは、本リポジトリ内で作業する AI エージェント（および参加者）向けの環境概要と開発の基本方針をまとめたものです。

---

## 環境概要（code-server）

実環境のインフラ定義は `environment/` 配下の AWS CDK にあります。要点は以下の通りです。

### デプロイ構成

- `environment/` 配下の CDK で EC2 インスタンスをデプロイする。
- インスタンス上で **code-server** が稼働し、参加者はブラウザからアクセスする。
- `ubuntu` ユーザのホームディレクトリ（`/home/ubuntu`）直下に本リポジトリをクローンして作業する。
  - **本リポジトリ直下が code-server のワークスペースルート**になる。

### インスタンス / OS

- OS: **Ubuntu 24.04 LTS**（x86_64 / amd64）
- インスタンスタイプ: `t3.medium`（ルートボリューム 80GB gp3）
- 配置: VPC のパブリックサブネット（パブリック IP 付与、NAT Gateway なし）
- プリインストール済みの主なツール（`environment/lib/userdata/codeServer.sh` 参照）:
  - AWS CLI v2 / AWS SAM CLI
  - Docker（`ubuntu` ユーザは docker グループ所属）
  - **Python 3.14**（`python` / `python3.14`、pip 同梱）
  - Node.js（LTS）
  - Kiro CLI

### ネットワーク / セキュリティグループ

code-server は前段の **CloudFront** で HTTPS 終端し、オリジン（EC2）とは HTTP で通信します。
セキュリティグループのインバウンドは以下のみ許可されています（`environment/lib/constructs/codeServer.ts`）。

| ポート | 公開範囲 | 用途 |
| --- | --- | --- |
| 50443 | CloudFront マネージドプレフィックスリストのみ | code-server 本体（CloudFront 経由でのみ到達） |
| 8080 | `0.0.0.0/0`（全公開） | Web サーバ（Python `http.server` など。インターネットから直接アクセス可能） |
| 8501 | `0.0.0.0/0`（全公開） | Streamlit（インターネットから直接アクセス可能） |
| 22 | whitelist の IP のみ（既定は空 = 実質閉） | SSH 管理用 |

> **重要 — ポートの到達性について**
> - **8080（Web サーバ）/ 8501（Streamlit のデフォルトポート）はいずれもインターネットに直接公開されている。** `http://<インスタンスのパブリック IP>:<ポート>` でブラウザから直接アクセスできる。
> - これらのポートを 0.0.0.0 で待ち受けるよう起動すること（localhost のみだと外部から到達できない）。code-server のポートフォワーディング（プロキシ）機能経由でのプレビューも併用可能。

---

## 開発の基本方針

### Web サーバを作る場合

- リポジトリ直下に **`workspace` フォルダ**を作成し、その中を**ドキュメントルート**とする。
- Python の標準 `http` モジュールでサーバを起動する。
- **ポートは 8080** を使用する。

```bash
mkdir -p workspace
cd workspace
python -m http.server 8080
```

8080 はインターネットに直接公開されているため、`http://<インスタンスのパブリック IP>:8080` で直接アクセスできる（`python -m http.server` は既定で 0.0.0.0 で待ち受ける）。

### Streamlit を使う場合

- 同様に **`workspace` フォルダ**を作成し、その中をアプリのルートとする。
- **ポートは Streamlit のデフォルト（8501）** を使用する（セキュリティグループで 8501 が公開済み）。

```bash
mkdir -p workspace
cd workspace
streamlit run app.py
# 既定で http://0.0.0.0:8501 で待ち受ける
```

8501 はインターネットに直接公開されているため、`http://<インスタンスのパブリック IP>:8501` で直接アクセスできる。

### 開発タスク完了後のルール（アクセス URL の通知）

Web サーバや Streamlit など、ブラウザでアクセスできる成果物を伴う開発タスクを完了したら、
**現在のインスタンスのパブリック IP を調べ、`http://<パブリック IP>:<ポート>` 形式のアクセス URL をユーザに返すこと。**

パブリック IP は EC2 メタデータ（IMDSv2）から取得する:

```bash
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)
echo "http://${PUBLIC_IP}:8080"   # 例: Web サーバ（8080）の場合
```

> パブリック IP はインスタンス停止・再起動で変わり得るため、URL は固定値としてハードコードせず、完了時に毎回取得し直すこと。

---

## 補足

- インフラ（CDK）の詳細は `environment/CLAUDE.md` および `environment/` 配下を参照すること。
- 本ファイルの記述と `environment/` の CDK 実装に差異が生じた場合は、**CDK 実装側が正**。作業前に必ず最新のセキュリティグループ設定を確認すること。
