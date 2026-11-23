# Decision Journal

每當發現自己停在一個抉擇超過約 20 分鐘，就記一筆（5 分鐘內寫完）。

## 2026-11-20 — M1.2½ IAM 最小化的四堂課
- 抉擇：apply 被 ec2:CreateVpcEndpoint 拒絕後如何處理
- 選了：不去 console 亂加權限湊合，走「repo JSON 為 SSOT」流程：對帳 live policy → 發現 Task5 drift（當初 console 加過沒回寫 repo）→ 抄回消 drift → 補 Task5＋M1 statements → 同步 live → 新 SSO session → dry-run 驗證 → apply
- 連鎖教訓：(1) 讀寬寫窄——ec2:Describe* 放寬（唯讀無害、需求集合由 provider 決定不可預測），寫操作維持逐 task 精確；(2) IAM action 單複數無規律——DeleteVpcEndpoints/DescribeVpcEndpoints 複數、Create/Modify 單數，被拒時逐字讀錯誤訊息裡的 action 名；(3) tainted resource——create 後讀取失敗會標記 tainted，下次 apply 先毀後建，「看到 destroy 了沒叫 destroy 的東西」第一假設就是它
- （least privilege 實戰、drift 處理、SSO session 語義、dry-run 驗證）

## 2026-11-20 — 動態 admin IP vs /32 白名單
- 抉擇：家寬 IP 在 .34/.37 之間間變動，遲早把自己鎖在 SG 外
- 選了：現階段維持 variable＋手動改；更優解法譜系記下（Session Manager 不開 22 埠、或放寬到 /24）

## 2026-11-20 — NAT 緩議（FinOps 數字修正版）
- 選了：VPC Endpoints 先於 NAT。S3 gateway endpoint 完全免費；ECR×2＋Logs 三個 interface endpoints 約 US$0.01/AZ-小時（≈US$7.30/AZ-月）＋約 US$0.01/GB → 單 AZ ≈US$22/月；NAT ap-east-1 ≈US$45/月＋US$0.045/GB，interface endpoint 每 GB 處理費便宜約 78%
- 修正：早前「endpoints 免費」的說法不精確——interface 型是計費的；單 AZ 是 dev 的成本取捨（AWS 建議 ≥2 AZ）
- （break-even 思維、per-AZ 計費乘數）

## 2026-11-20 — M1.0 基線從零建立
- 抉擇：plan 顯示 11 資源全建 → 判斷 state 空（Task A 後帳號歸零，destroy 清空 state）
- 選了：state 空＋雲端空的對帳證據齊 → apply 建基線 → SSH 驗證三合一（SSH＋出網＋SG /32）
- （state 與雲端一致性判斷）