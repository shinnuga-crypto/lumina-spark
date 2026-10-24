# GitHub公開準備

2026-10-24 / GPT

- 指定アカウント：`shinnuga-crypto`（接続済みGitHub連携で確認）。公開リポジトリを希望。
- 予定リポジトリ：`shinnuga-crypto/lumina-spark`。現時点はGitHub CLI未ログインのため未作成・未プッシュ。
- ソース：このゲームのファイルと履歴だけを `git subtree split --prefix="Projects/ゲーム/Lumina Spark" HEAD` で抽出する。親のCodexリポジトリをそのままプッシュしない。親リポジトリにリモートを追加しない。
- 配布：`build/windows/LuminaSpark.exe`、`build/LuminaSpark-v1.0.0-windows-x64.zip`、`build/SHA256SUMS.txt` をGitHub Releasesの `v1.0.0` へ添付する。EXE/ZIPはGit履歴に入れない。
- リリース本文：`RELEASE_NOTES.md`。

ユーザー側のPowerShellで `gh auth login` を実行し、本人のGitHubアカウントにログイン後に公開を継続する。認証コードやトークンはチャットに貼らない。

公開時は既存リポジトリが同名で存在しないかを再確認し、既存内容を上書きしない。新規作成時は `--public`。ソースの抽出コミットを `main` に通常プッシュし、同じコミットを対象にリリースを作成する。完了後にリポジトリと添付ファイル名・サイズをAPIで再確認し、この文書と引き継ぎを更新する。
