# GitHub公開記録・更新手順

**2026-10-25 最新方針：テスト制作中のため、GitHubへは今後上げない。新たな明示依頼があるまでpush・Release作成を停止し、ローカル制作と検証に留める。公開済みのものは削除しない。以下の更新手順は公開依頼を受けた場合だけ適用する。**

2026-10-24 / GPT

- 公開リポジトリ：[shinnuga-crypto/lumina-spark](https://github.com/shinnuga-crypto/lumina-spark)。mainへプッシュ済み。
- 配布リリース：[v1.0.0](https://github.com/shinnuga-crypto/lumina-spark/releases/tag/v1.0.0)。EXE・ZIP・SHA256SUMS.txtを添付済み。公開状態と全ファイルのuploaded状態・サイズをAPIで確認。EXEとZIPのGitHub側SHA-256はローカルと一致。
- 2026-10-24 Claude：[v1.1.0](https://github.com/shinnuga-crypto/lumina-spark/releases/tag/v1.1.0) を追加（弾幕・鬼弾幕、設定画面など）。`tools/build-windows.ps1` の既定の版を1.1.0に、`export_presets.cfg` の版を1.1.0.0に。
- 2026-10-25 GPT：[v1.2.0](https://github.com/shinnuga-crypto/lumina-spark/releases/tag/v1.2.0) を追加（地上・下降地下、新敵4/ボス2、全方向のボーン射撃）。ビルド既定1.2.0、EXE157,277,616バイト、ZIP86,843,105バイト。非draft・3添付uploaded・EXE/ZIPのdigest一致をAPIで確認。
- 2026-10-25 GPT：[v1.2.1](https://github.com/shinnuga-crypto/lumina-spark/releases/tag/v1.2.1) を追加（ギミック作画15点、パッド1機能4枠）。ビルド既定1.2.1、EXE160,286,272バイト、ZIP89,809,381バイト。非draft・3添付uploaded・EXE/ZIPのdigest一致を確認。主人公のモーションは相談待ちで未変更。
- 2026-10-25 GPT：[v1.3.0](https://github.com/shinnuga-crypto/lumina-spark/releases/tag/v1.3.0) を追加（溜め斬り3段階、地上/空中/ダッシュのボーン動作、射撃ジャンプ遷移）。EXE161,059,216バイト、ZIP90,539,222バイト。非draft・3添付uploaded・digest一致。
- ソース：このゲームのファイルと履歴だけを `git subtree split --prefix="Projects/ゲーム/Lumina Spark" HEAD` で抽出する。親のCodexリポジトリをそのままプッシュしない。親リポジトリにリモートを追加しない。
- 配布：`build/windows/LuminaSpark.exe`、`build/LuminaSpark-v<版>-windows-x64.zip`、`build/SHA256SUMS.txt`。EXE/ZIPはGit履歴に入れずGitHub Releasesへ添付する。
- リリース本文：`RELEASE_NOTES.md`。

認証は通常のGit保存済み認証（Git Credential Manager）を使用。追加の `gh auth login` は不要だった。CLIだけのログイン状態を見て作業を止めず、先に通常のGitで接続を確認する。リポジトリ作成とRelease添付では、Gitが設定済みの資格情報ヘルパーを通して取得した認証をCLIのプロセス環境内だけで使用した。認証値は表示・ファイル保存しない。

更新時は公開先を再確認し、ソースの抽出コミットを `main` に通常プッシュする（強制プッシュしない）。新バージョンのReleaseを作成して配布物を添付し、ファイル名・サイズ・SHA-256をAPIで再確認する。親リポジトリにはリモートを追加していない。
