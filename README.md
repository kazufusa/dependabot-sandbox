# dependabot-sandbox

Dependabot の動きを試すためのサンドボックスです。
依存の版をわざと古いものに固定してあり、Dependabot を動かすと更新の PR が出ます。

## 構成

| 場所 | 内容 |
|---|---|
| `pyproject.toml`・`uv.lock`・`shared/`・`slack/` | uv workspace |
| `web/api/` | workspace の外の独立した uv プロジェクト |
| `web/ui/` | 版を完全固定にした npm プロジェクト |
| `web/ui-caret/` | 版を `^` の範囲にした npm プロジェクト |
| `web/mock/` | `dependabot.yml` の対象にしていないディレクトリ |
| `web/`・`web-fromuv/`・`shared/migrations/`・`tools/gitleaks/` | Dockerfile |
| `infra/terraform/` | Terraform の `versions.tf` と lock ファイル |
| `.github/workflows/` | 検査と、Dependabot の PR を扱う workflow |

## 設定の切り替え

リポジトリ設定と ruleset は、次のスクリプトで切り替えます。

```sh
scripts/apply-settings.sh base
scripts/apply-settings.sh strict
```

`strict` は、auto-merge、コード所有者のレビュー必須、必須の検査、Dependabot alerts を有効にします。
CODEOWNERS は `settings/CODEOWNERS.base` と `settings/CODEOWNERS.strict` を用意しています。

レビュー依頼の宛先は、リポジトリ変数で決めます。
`REVIEW_TEAM` に team の slug を入れると team に依頼し、空なら `REVIEWER` の個人に依頼します。

## 確認できたこと

2026-11-14 の時点で、実際に動かして確かめた結果です。観察したのは半日ほどで、長い期間の運用はまだ見ていません。

### 自動マージ

| 項目 | 結果 |
|---|---|
| ロックファイルだけを変える PR の自動マージ | できました。bot の承認と必須の検査だけで、3 本がマージされました（#5、#19、#15） |
| 所有者のいるファイルを変える PR | bot が承認してもマージされず、所有者のレビュー待ちで止まりました |
| `automerge` ラベル | auto-merge を予約した PR に付きます |
| 1 本マージされたあとの残りの PR | ブランチが古くなって止まりました。同じファイルを触って衝突した PR は、Dependabot が 2〜3 分で自分から取り込み直しました。衝突の無い PR は 50 分ほど古いままで、`@dependabot rebase` と書くと 1〜2 分でマージまで進みました |
| patch のグループだけに限る判定 | workflow に入れましたが、該当する PR がまだ出ておらず、動きは未確認です |

### レビューの依頼

| 項目 | 結果 |
|---|---|
| PR の作成のときの依頼 | workflow から個人への依頼が付きました |
| CODEOWNERS による依頼 | 所有者に自動で付きました |
| `assignees` | 担当者が付きました |
| team への依頼と、一部の人にだけ届く通知 | 個人アカウントのリポジトリでは試せていません |

### 更新の PR が出る範囲

| 対象 | 結果 |
|---|---|
| uv（workspace と独立したプロジェクト） | 出ました |
| npm | 出ました |
| Dockerfile の `FROM` | 4 つのディレクトリが 1 本にまとまって出ました。`-slim` は保たれ、`gitleaks.Dockerfile` のような名前のファイルも拾われました |
| Dockerfile の `COPY --from` に書いた版 | 更新されません。`FROM … AS …` の段に直すと更新されます |
| GitHub Actions | コミットの SHA と、コメントの版の両方が更新されました |
| Terraform のプロバイダ | 出ました。`versions.tf` と lock ファイルの両方が変わりました |
| Terraform 本体の版 | Dependabot の対象外なので、workflow で PR を作りました。ただし `GITHUB_TOKEN` で作った PR では検査が動かず、必須の検査が結果を返さないため、マージできません |
| `dependabot.yml` に書いていないディレクトリ | バージョン更新の PR は出ませんでした |

### versioning-strategy

| 値 | uv | npm（`^` の範囲） | npm（完全固定） |
|---|---|---|---|
| `increase-if-necessary` | 範囲の中の更新でも `pyproject.toml` の下限が変わりました | 範囲の中は `package-lock.json` だけ、範囲を超えると `package.json` も変わりました | 全部の更新で `package.json` が変わりました |
| `lockfile-only` | `uv.lock` だけが変わりました。範囲を超える更新と、完全固定の依存の PR は出ません | `package-lock.json` だけが変わりました | PR が出ません |
| `increase`・`auto` | 下限が変わりました | 範囲の中の更新でも `package.json` が変わりました | 全部の更新で `package.json` が変わりました |
| `widen` | この値にしたあと、Dependabot の実行が起きませんでした。原因は未確認です | 同じ | 同じ |

## 残っている課題

- uv には、範囲の中はロックファイルだけ、範囲を超えると `pyproject.toml` も変える、という値が見つかっていません。`lockfile-only` にすると自動マージはできますが、範囲を超える更新の PR が出なくなります
- 必須の検査に「ブランチを最新にしてからマージ」を付けると、自動マージが 1 本ごとに待たされます。衝突の無い PR を Dependabot が自分で取り込み直すまでの時間は、まだ分かっていません。merge queue を使えば待ちは無くなりますが、個人アカウントのリポジトリでは使えません
- Dockerfile の更新は最新の版まで一度に上がりました（Python は 3.14 から 3.15、Node は 24 から 26）。patch だけを自動で上げるには、minor と major を `ignore` する設定が要ります
- セキュリティ更新は依存ごとに PR が出ます。自動マージの対象から外す判定は入れましたが、動きは未確認です
- 待機期間（`cooldown`）の効き方と、1 週間あたりの PR の本数は、まだ見ていません
