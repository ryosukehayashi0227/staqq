#!/bin/bash

# 1. すべての変更をステージングに上げる
echo "📂 すべての変更をステージングに追加中..."
git add .

# 2. 差分があるか確認
if git diff --cached --quiet; then
  echo "⚠️ 変更が見つかりませんでした。終了します。"
  exit 0
fi

# 3. Geminiにコミットメッセージを生成させる
echo "🤖 Geminiがコミットメッセージを生成中..."
# パイプで渡す際に、余計なツールを使わせないよう指示を強化します
COMMIT_MSG=$(git diff --cached | gemini "あなたは純粋なテキスト変換器です。以下の差分テキストのみを参照し、ツールや外部コマンドを一切使用せずに、Conventional Commits形式のメッセージ1行だけを出力してください。思考プロセスや解説、コマンド提案は厳禁です。")

# ※もし gemini コマンドが --raw などのオプションを持っている場合は追加してください
# 例: gemini --raw "..."

if [ -z "$COMMIT_MSG" ]; then
  echo "❌ メッセージの生成に失敗しました。"
  exit 1
fi

echo "📝 生成されたメッセージ: $COMMIT_MSG"

# --- 以下、前回のスクリプトと同じ ---
git commit -m "$COMMIT_MSG"
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
git push origin "$BRANCH_NAME"

echo "📄 PR本文を生成中..."
PR_BODY=$(git diff main...HEAD | gemini "この差分を要約し、GitHubのPR用説明文を日本語のMarkdownで作成してください。ツールは使用せずテキストのみ返してください。")

gh pr create --title "$COMMIT_MSG" --body "$PR_BODY"
echo "✅ 完了！"
