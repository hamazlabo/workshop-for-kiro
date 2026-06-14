---
name: sdd-plan
description: >-
  Interactively create a spec for spec-driven development (SDD) by talking with
  the user. Produces four documents under .spec/<feature-name>/:
  requirements.md, design.md, plan.md, and task.md. Use when the user wants to
  plan a new app/feature, start spec-driven development, write requirements, a
  design doc, a technical plan, or a task list before implementation. Trigger
  phrases: "仕様を作りたい", "spec を作る", "要件定義", "設計から始めたい",
  "plan an app", "create a spec", "sdd-plan".
---

# sdd-plan — 対話的に spec を作成する

ユーザと**対話しながら**、spec 駆動開発(SDD)の 4 ドキュメントを順番に作成するスキルです。
各ドキュメントはユーザの承認を得てから次へ進みます。**ユーザに代わって要件を勝手に決めず、必ずヒアリングすること。**

## 成果物と配置

すべて `.spec/` 直下に作成する(単発実行を想定し、feature ごとのサブディレクトリは作らない)。
各ドキュメントは **`.spec/templates/` のテンプレートをコピー**して使い、内容を埋めていく。

| ファイル | テンプレート | 役割 |
| --- | --- | --- |
| `requirements.md` | `.spec/templates/requirements.md` | ユーザのやりたい事をヒアリングして定義した、アプリの要件定義 |
| `design.md` | `.spec/templates/design.md` | 要件を元に作成したアプリの設計書 |
| `plan.md` | `.spec/templates/plan.md` | 設計を実現するための技術計画書 |
| `task.md` | `.spec/templates/task.md` | 実装するためのタスクリスト |

## 事前確認(必ず最初に行う)

1. このリポジトリの `AGENTS.md` を読み、ワークショップ環境の制約を把握する。
   - Web サーバは `workspace/` フォルダをドキュメントルートにし **ポート 8080**、Streamlit は **ポート 8501**。
   - OS は Ubuntu 24.04、Python 3.14 / Node.js / Docker / AWS CLI / SAM が利用可能。
   - 完成物のアクセス URL は `http://<パブリックIP>:<ポート>`。
2. `.kiro/steering/` にステアリングファイルがあれば読み、規約に従う。
3. テンプレートを `.spec/` 直下にコピーする:

   ```bash
   cp .spec/templates/*.md .spec/
   ```

   既に `.spec/` 直下に同名ファイルがある場合は、上書きしてよいかユーザに確認する。
   以降、コピーした各ファイルをフェーズごとに編集していく(テンプレート内の見出しや空欄を埋める)。

## ワークフロー

進め方の原則:
- **一度に 1〜3 個ずつ質問**し、回答を待ってからまとめる(質問攻めにしない)。
- 各ドキュメントを書いたら内容を要約して見せ、**「この内容で次へ進んでよいか」承認を得る**。修正要望があれば反映してから進む。
- 後段のドキュメントは前段の内容を必ず参照する。

### フェーズ 1: requirements.md(要件定義)

以下をヒアリングして埋める:
- アプリの目的 / 解決したい課題
- 想定ユーザと利用シーン
- 実現したい機能(箇条書き)
- 入出力・データの種類
- 非機能要件(性能・セキュリティ・対応ブラウザ等、ワークショップ規模に応じて簡潔に)
- スコープ外(やらないこと)

書式は「ユーザーストーリー + 受け入れ基準(箇条書き / EARS 形式可)」を推奨。
要件に番号を振り(例: `R1`, `R2`...)、後段から参照できるようにする。承認を得たら次へ。

### フェーズ 2: design.md(設計書)

requirements.md を元に設計する:
- 全体アーキテクチャ(構成図は ASCII やテキストで可)
- 画面 / 機能コンポーネントとその責務
- データモデル / 状態
- 外部 I/F・API(あれば)
- 各設計要素がどの要件(R番号)を満たすかを明記
- ワークショップ制約(ポート 8080 / 8501、`workspace/` 構成)を反映

承認を得たら次へ。

### フェーズ 3: plan.md(技術計画書)

design.md を実現するための技術計画:
- 技術スタック(言語・フレームワーク・ライブラリのバージョン。Python 3.14 前提)
- ディレクトリ構成(`workspace/` 配下を含む)
- 起動方法・ポート(Web=8080 / Streamlit=8501)
- 依存関係とセットアップ手順
- 実装順序(マイルストーン)
- リスク・未確定事項と対処方針

承認を得たら次へ。

### フェーズ 4: task.md(タスクリスト)

plan.md を実装可能な粒度に分解したチェックリスト:
- Markdown チェックボックス形式 `- [ ] T1: ...`
- 各タスクに ID(`T1`,`T2`...)、対応する要件(R番号)/設計要素を併記
- 依存関係(前提タスク)を明記し、**並行実行できるタスクが分かるようにする**(sdd-develop がサブエージェントへ委譲しやすくなる)
- 各タスクの完了条件(Done の定義)を 1 行で

## 完了時

4 ドキュメントのパスを一覧でユーザに提示し、「実装は `sdd-develop` スキルで行えます」と案内する。
