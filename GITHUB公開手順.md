# GitHub公開記録・更新手順

2026-10-24 / GPT

- 公開リポジトリ：[shinnuga-crypto/lumina-spark](https://github.com/shinnuga-crypto/lumina-spark)。mainへプッシュ済み。
- 配布リリース：[v1.0.0](https://github.com/shinnuga-crypto/lumina-spark/releases/tag/v1.0.0)。EXE・ZIP・SHA256SUMS.txtを添付済み。公開状態と全ファイルのuploaded状態・サイズをAPIで確認。EXEとZIPのGitHub側SHA-256はローカルと一致。
- ソース：このゲームのファイルと履歴だけを `git subtree split --prefix="Projects/ゲーム/Lumina Spark" HEAD` で抽出する。親のCodexリポジトリをそのままプッシュしない。親リポジトリにリモートを追加しない。
- 配布：`build/windows/LuminaSpark.exe`、`build/LuminaSpark-v1.0.0-windows-x64.zip`、`build/SHA256SUMS.txt`。EXE/ZIPはGit履歴に入れずGitHub Releasesへ添付する。
- リリース本文：`RELEASE_NOTES.md`。

認証は通常のGit保存済み認証（Git Credential Manager）を使用。追加の `gh auth login` は不要だった。CLIだけのログイン状態を見て作業を止めず、先に通常のGitで接続を確認する。リポジトリ作成とRelease添付では、Gitが設定済みの資格情報ヘルパーを通して取得した認証をCLIのプロセス環境内だけで使用した。認証値は表示・ファイル保存しない。

更新時は公開先を再確認し、ソースの抽出コミットを `main` に通常プッシュする（強制プッシュしない）。新バージョンのReleaseを作成して配布物を添付し、ファイル名・サイズ・SHA-256をAPIで再確認する。親リポジトリにはリモートを追加していない。
