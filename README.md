# cloud-lab

## 架構決策記錄（ADR）
| 日期 | 決策 | 理由 |
|------|------|------|
| 2026-10-02 | AWS + Terraform + S3/DynamoDB 後端 | 職場主流、原生鎖定、免費額度內 |
| 2026-10-02 | 多帳號：Management + personal-dev | 爆炸半徑隔離；Prod 帳號延後建立 |

## 目錄結構
bootstrap/  一次性基礎設施（state bucket）
envs/dev/   開發環境入口
modules/    可重用模組

## 環境資訊
- Dev Account ID: &lt;填你的 12 碼 ID&gt;
- State Bucket: tf-state-433269483086
- Terraform 版本: v1.16.0