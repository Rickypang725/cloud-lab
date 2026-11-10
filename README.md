# Cloud Lab — AWS VPC Infrastructure as Code

&gt; 從零到有公網的安全 VPC，全程 IaC 紀律：每個任務一筆 commit、
&gt; 每個決策寫明原因、每步驗收有 plan/CLI 證據，並親手驗證全毀重建。

## Architecture

```mermaid
flowchart TD
    Internet --&gt; IGW
    IGW --&gt;|0.0.0.0/0| RT[Route Table public]
    RT --&gt;|association| PS[Public Subnet&lt;br&gt;10.0.1.0/24 · public_a]
    PS --&gt; SG[Security Group&lt;br&gt;ingress tcp/22 ← admin/32]
    SG --&gt; EC2[EC2 t3.micro · AL2023]
```

## Address Plan

| 區段 | CIDR | 狀態 |
|---|---|---|
| VPC | 10.0.0.0/16 | ✅ |
| Public (ap-east-1a) | 10.0.1.0/24 | ✅ |
| Private | 10.0.2.0/24 | Roadmap |
| Spare | 10.0.3.0/24+ | Reserved |

## Tech Stack

AWS (VPC/EC2/IAM) · Terraform · Git · Amazon Linux 2023

## Why This Repo Is Different

- **決策有理由**：不動預設 main route table（預設封閉）、SG /32 白名單（零信任）、
  CIDR 先規劃（單向門）——每個 commit message 的 why 欄都寫著原因
- **證據驅動**：每個任務 = plan 對基線 + `aws ec2 describe-*` 截點 + 實測（curl/SSH）
- **可重現**：`terraform destroy && terraform apply` 從空帳號回到 SSH 可登入，全程一鍵
- **狀態掌控**：taint/untaint、import 收編 orphan、`state mv` 零中斷 refactor、
  perpetual diff 防禦（lifecycle.ignore_changes）

## Task History (= commit log)

| Task | 內容 |
|---|---|
| 1 | VPC 10.0.0.0/16 |
| 2 | IGW attach（1:1） |
| 3 | Public Subnet |
| 4 | Route Table 接通 IGW |
| 5 | SG 白名單 + Key Pair + EC2 |
| A | 破壞與重建：targeted destroy / 全毀 / 一鍵重建 / state 手術 |

## Reproduce

```bash
terraform init
terraform apply        # ~2 min 從零到可 SSH 的完整網路
terraform destroy      # 帳號歸零
```

## Roadmap

Private Subnet → NAT Gateway → SG-to-SG → Multi-AZ
