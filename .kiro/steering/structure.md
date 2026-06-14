# ディレクトリ構成 / ファイル配置の規約

## リポジトリ全体

```
.（リポジトリ直下 = code-server のワークスペースルート）
├── AGENTS.md              # 環境概要と開発の基本方針（最優先で参照）
├── workspace/             # ★ アプリの実装・起動はすべてここで行う
├── .spec/                 # spec 駆動開発の成果物
│   ├── templates/         #   spec の雛形（コピー元・編集しない）
│   ├── requirements.md    #   sdd-plan が templates からコピーして作成・編集
│   ├── design.md
│   ├── plan.md
│   └── task.md
├── .kiro/                 # Kiro CLI 設定
│   ├── agents/            #   カスタムエージェント定義（sdd / sdd-worker）
│   ├── skills/            #   スキル定義（sdd-plan / sdd-develop）
│   └── steering/          #   ステアリング（このファイル群）
└── environment/           # ワークショップ環境の AWS CDK（インフラ。アプリ開発では触らない）
```

## 配置の原則

- **アプリのコードと成果物は必ず `workspace/` 配下**に置く。リポジトリ直下を散らかさない。
- spec 駆動開発の 4 ドキュメントは `.spec/` 直下に置く（feature ごとのサブディレクトリは作らない、単発実行前提）。雛形は `.spec/templates/` から `cp` して使う。
- `environment/`（CDK）はインフラ定義。アプリ開発タスクでは変更しない。

## アプリ別の構成イメージ

### 1 回目: テトリス（`workspace/` を 8080 で配信）

```
workspace/
├── index.html
├── style.css
└── tetris.js
```

### 2 回目: AI チャット（`workspace/` を Streamlit 8501 で起動）

```
workspace/
├── app.py                 # Streamlit + Strands Agents のエントリポイント
├── requirements.txt       # strands-agents / strands-agents-tools / streamlit
└── sessions/              # FileSessionManager の storage_dir（会話履歴の永続先）
```

> 注: 2 つのアプリを同じ `workspace/` で続けて作る場合は、1 回目の成果物を別フォルダへ退避するか、`workspace/` を作り直してから始める（手順側で指示する）。
