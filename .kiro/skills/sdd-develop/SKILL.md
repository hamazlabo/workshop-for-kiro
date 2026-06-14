---
name: sdd-develop
description: >-
  Implement an application from an existing spec created by sdd-plan. Reads the
  four documents (requirements.md, design.md, plan.md, task.md) under
  .spec/<feature-name>/ and builds the app, delegating isolated or
  parallel tasks to the sdd-worker subagent. Use when the user wants to
  implement, build, or develop an app from a spec, execute the task list, or
  continue spec-driven development. Trigger phrases: "実装して", "spec から作って",
  "開発を進めて", "タスクを実装", "implement the spec", "build the app",
  "sdd-develop".
---

# sdd-develop — spec を読み込んでアプリを実装する

`sdd-plan` で作成した 4 ドキュメントを読み込み、アプリを実装するスキルです。
このスキルを実行するエージェントは **orchestrator** として振る舞い、必要に応じて **`sdd-worker` サブエージェント**へタスクを委譲します。

## 事前確認(必ず最初に行う)

1. このリポジトリの `AGENTS.md` を読み、ワークショップ環境の制約を把握する。
   - Web サーバ: `workspace/` をドキュメントルートに **ポート 8080**(`python -m http.server 8080`)。
   - Streamlit: **ポート 8501**。
   - Python 3.14 / Node.js / Docker / AWS CLI / SAM が利用可能。
   - **完了後は現在のパブリック IP を取得し、`http://<パブリックIP>:<ポート>` のアクセス URL をユーザに返す。**
2. `.spec/` 直下から **requirements.md / design.md / plan.md / task.md を全て読む**(`.spec/templates/` は雛形なので対象外)。
3. `.kiro/steering/` があれば規約に従う。

## 実装ワークフロー

### 1. 計画の把握

- task.md のタスク一覧・依存関係・完了条件を読み取る。
- design.md / plan.md のアーキテクチャ・技術スタック・ディレクトリ構成を確認する。
- plan.md に従い `workspace/` などのディレクトリと初期ファイル(依存定義等)を用意する。

### 2. タスクの実行と委譲

task.md を**上から依存順に**実行する。各タスクについて:

- **委譲の判断**:
  - 独立して進められる / 並行可能 / コンテキストを分離した方がよいタスクは、`sdd-worker` サブエージェントへ委譲する。
  - 委譲時は「対象タスク ID・関連する要件(R番号)と設計箇所・完了条件・触ってよいファイル範囲」を明確に指示する。
  - 互いに依存しない複数タスクは、サブエージェントへ**並行して**委譲してよい。
- **自分で実行**: 横断的な結合・全体方針に関わる部分や、軽微なタスクは orchestrator 自身で実装する。
- サブエージェントの結果を受け取り、整合性を確認して統合する。

### 3. 進捗の反映

- 完了したタスクは task.md のチェックボックスを `- [x]` に更新する。
- 設計と実装に乖離が生じた場合は design.md / plan.md を追記・修正し、理由を残す。

### 4. 動作確認

- plan.md の起動方法に従いアプリを起動して動作確認する(Web=8080 / Streamlit=8501、0.0.0.0 で待ち受け)。
- エラーがあれば修正し、必要なら再度サブエージェントへ委譲する。

## 完了時(必須)

1. 実装したファイル・主な変更点を要約する。
2. task.md の消化状況(完了 / 残タスク)を提示する。
3. **AGENTS.md のルールに従い、現在のパブリック IP を取得してアクセス URL を返す**:

   ```bash
   TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
     -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
   PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
     http://169.254.169.254/latest/meta-data/public-ipv4)
   echo "http://${PUBLIC_IP}:8080"   # ポートは実装に合わせる
   ```

   IP はインスタンス再起動で変わるためハードコードせず、毎回取得し直すこと。
