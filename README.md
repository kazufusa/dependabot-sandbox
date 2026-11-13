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
