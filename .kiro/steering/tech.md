# 技術スタック / 技術的制約

環境の詳細（OS・セキュリティグループ・ポート公開状況）は `AGENTS.md` を参照すること。ここでは各アプリの技術方針をまとめる。

## 共通環境

- OS: Ubuntu 24.04 LTS
- 言語: **Python 3.14**（`python` / `python3.14`、pip 同梱）。他に Node.js / Docker / AWS CLI / SAM が利用可能。
- 実行場所: リポジトリ直下の `workspace/` フォルダ内で開発・起動する。
- 公開ポート（セキュリティグループで全公開済み）:
  - Web サーバ = **8080**
  - Streamlit = **8501**
- サーバは必ず **0.0.0.0** で待ち受ける（localhost のみだと外部から到達できない）。

## 1 回目: テトリス

- **構成**: 静的フロントエンド（HTML / CSS / JavaScript）のみ。バックエンド不要。
- **配信**: Python 標準の http サーバでドキュメントルートを配信する。
  ```bash
  cd workspace
  python -m http.server 8080
  ```
- **公開 URL**: `http://<パブリックIP>:8080`

## 2 回目: AI チャット（Strands Agents + Streamlit）

### エージェントフレームワーク: Strands Agents

- インストール:
  ```bash
  pip install strands-agents strands-agents-tools
  ```
- モデルプロバイダは **Amazon Bedrock**。
- **リージョンとモデルはワークショップ共通で固定する**:
  - リージョン: **us-west-2（オレゴン）**
  - モデル: **GLM-5**（Bedrock モデル ID: **`zai.glm-5`**。us-west-2 で利用可能）
  - 認証: EC2 インスタンスにアタッチされた **IAM ロール**の認証情報を利用する（AWS CLI 同様）。事前に us-west-2 で **Bedrock の GLM-5 モデルアクセスを有効化**しておくこと。
- 必ず `BedrockModel` で上記を明示し、既定モデルにフォールバックさせない:
  ```python
  from strands import Agent
  from strands.models import BedrockModel

  bedrock_model = BedrockModel(
      model_id="zai.glm-5",
      region_name="us-west-2",
  )
  agent = Agent(model=bedrock_model)
  agent("Hello!")
  ```

### 会話履歴管理: FileSessionManager

- 会話・エージェント状態をローカルファイルに永続化する。
  ```python
  from strands import Agent
  from strands.models import BedrockModel
  from strands.session.file_session_manager import FileSessionManager

  bedrock_model = BedrockModel(model_id="zai.glm-5", region_name="us-west-2")
  session_manager = FileSessionManager(
      session_id="chat-session",
      storage_dir="workspace/sessions",  # ← プロジェクト内に固定
  )
  agent = Agent(model=bedrock_model, session_manager=session_manager)
  ```
- **注意点**:
  - `storage_dir` を**必ずプロジェクト内のパス**（例: `workspace/sessions`）に設定する。未指定だと `/tmp/strands/sessions` に保存され、再起動で消える。
  - 同一 `session_id` への並行書き込みはデータ破損の恐れがある（排他制御なし）。1 セッション = 1 書き込み元とする。

### UI: Streamlit

- インストール:
  ```bash
  pip install streamlit
  ```
- 起動（既定ポート 8501、外部公開のため 0.0.0.0 で待ち受け）:
  ```bash
  cd workspace
  streamlit run app.py --server.address 0.0.0.0 --server.port 8501
  ```
- **公開 URL**: `http://<パブリックIP>:8501`
- チャット UI は Streamlit の `st.chat_message` / `st.chat_input` を基本に構成する。

## 完了時の共通ルール

実装完了後は IMDSv2 で現在のパブリック IP を取得し、`http://<パブリックIP>:<ポート>` のアクセス URL をユーザに返す（`AGENTS.md` 参照）。IP は再起動で変わるためハードコードしない。
