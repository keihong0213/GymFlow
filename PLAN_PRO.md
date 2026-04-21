# Kintore Pro — 商業化規劃

_草擬日期: 2026-04-21_

免費版保持所有現有功能不動。Pro 只加新功能，不移除任何現有免費能力。

---

## 一、觸發條件（何時開始做）

- [ ] App 上架後累積 **500+ 活躍用戶**（DAU ≥ 50）
- [ ] 有 **20+ 真實 App Store 評論**
- [ ] 至少 **3 個月**的真實使用數據，確認哪些功能最常被使用
- [ ] 收到 **≥ 10 則使用者明確要求付費功能**（email/issue）

若觸發條件未滿足就推 Pro，會被 App Store 評論打爆「還沒做好就想賺錢」。

---

## 二、Pro 功能清單（按優先級）

### Tier 1：Must-have（MVP Pro）

這四項是 Pro 的核心賣點，沒這些不叫 Pro。

1. **進階統計儀表板**
   - 每個動作的 e1RM 趨勢圖（折線 + PR 標記）
   - 每週 / 每月 volume 統計
   - 肌群訓練量分布（雷達圖）
   - 訓練頻率熱力圖（GitHub-style contribution graph）
   - 休息時間平均值、訓練時長趨勢

2. **iCloud 同步**
   - 跨裝置（iPhone / iPad）同步訓練資料
   - 換新手機時資料自動還原
   - 技術路線：CloudKit + CKSyncEngine（iOS 17+）
   - 注意：需更新隱私權政策（資料會上 iCloud，但只有使用者自己看得到）

3. **無限自訂動作與課表**
   - 免費版上限：10 個自訂動作、3 個課表
   - Pro 無上限
   - 匯入/匯出單一課表（分享給朋友）

4. **進階匯出**
   - 排程自動備份（每週 / 每月到 iCloud Drive）
   - 匯出 PDF 訓練報告（月/季/年）
   - Google Sheets 格式匯出

### Tier 2：Nice-to-have（第二波更新）

5. **Apple Watch 伴侶 app**
   - 手腕直接紀錄組數
   - 休息計時器振動通知
   - 與 iPhone 即時同步

6. **主畫面 Widget**
   - 今日訓練預覽
   - 連續訓練天數（streak）
   - 本週 volume 進度環

7. **Shortcuts 整合**
   - Siri：「Hey Siri, start my chest day」
   - 自動化：離開健身房位置時自動結束訓練

8. **身體組成追蹤**
   - 體重、體脂、圍度隨時間變化
   - 與 Apple Health 雙向同步（現在只寫入 workout）
   - 體重 vs 肌力 correlation 圖

### Tier 3：Future ideas（觀察再說）

9. **AI 訓練建議**（用 on-device Core ML，不上傳）
   - 根據歷史推薦下次重量
   - 偵測停滯並建議 deload

10. **社群功能**（極簡，不違背核心精神）
    - 分享訓練成就圖片
    - 與朋友比較 PR（對方需同意）

---

## 三、定價策略

### 價格點

| 方案 | 價格 | 說明 |
|------|------|------|
| **Pro 月訂閱** | $1.99 USD / 月 | 低門檻試用 |
| **Pro 年訂閱** | $14.99 USD / 年（$1.25/月） | 主推方案，節省 37% |
| **Pro Lifetime** | $29.99 USD 一次買斷 | 重度使用者，不用續費 |

台幣對應：
- 月: NT$60
- 年: NT$490
- Lifetime: NT$990

### 試用策略

- **7 天免費試用**（訂閱自動續費）
- 試用期內可隨時取消，不扣款

### Paywall 觸發點

不要一開啟 app 就 paywall。應該在「使用者想用特定功能」時觸發：

- 點「進階統計」tab → paywall
- 自訂動作超過 10 個 → paywall
- 開啟 iCloud 同步 → paywall
- 設定自動備份 → paywall

按鈕文案：**「解鎖 Kintore Pro」** 而不是「立即購買」

---

## 四、技術實作

### 套件

- **RevenueCat**（推薦）或 StoreKit 2 原生
  - RevenueCat 免費額度：$2,500/月 tracked revenue
  - 多平台、多訂閱方案管理方便、有 webhook
  - 若只做 iOS 一個平台、只有一種訂閱，也可用 StoreKit 2

### 架構改動

1. **新 Package: `GymFlowPro`**
   - `ProEntitlement` 檢查（@Observable）
   - `PaywallView`（SwiftUI）
   - `SubscriptionManager`（呼叫 RevenueCat / StoreKit）

2. **Feature flag 模式**
   ```swift
   if proEntitlement.isActive {
       // show advanced charts
   } else {
       // show paywall CTA
   }
   ```

3. **iCloud 同步**
   - 新增 `CloudSyncService`（CloudKit）
   - 現有 SQLite 仍為 single source of truth
   - 背景上傳 change log 到 CloudKit private database
   - 衝突解決：last-write-wins（健身紀錄衝突極少）

### 資料庫變更

- 新增 `schema_version` 欄位支援 Pro 設定（已有）
- 新增 `iCloudSyncToken`、`lastSyncedAt` 欄位到使用者設定
- 免費/Pro 不影響核心 schema

---

## 五、行銷與上架

### App Store 定位

- **免費 app, IAP 可選**（不要改成付費 app）
- 描述頁強調：「**免費版已完整可用**，Pro 是給想看更多數據的人」
- 避免「試用期結束會被鎖定」的觀感

### 內購項目名稱

- 英文：`Kintore Pro Monthly / Yearly / Lifetime`
- 中文：`Kintore Pro 月訂閱 / 年訂閱 / 終身解鎖`

### 推出時機

- 不要在 v1.0 就推 Pro。先 v1.0 純免費上架 → 3 個月後推 v1.3 加入 Pro
- 老用戶給 **50% off lifetime**（限時一週）回饋

---

## 六、法務 / 合規

- [ ] 更新隱私權政策：加入 iCloud 同步章節（資料可能離開裝置到使用者自己的 iCloud）
- [ ] 更新 App Store 隱私問卷：訂閱資訊會收集
- [ ] 訂閱條款（EULA）：標準 Apple EULA 即可，無需客製
- [ ] 台灣／日本／韓國：按當地稅法申報（Apple 會代扣代繳）

---

## 七、預期收入模型

假設 6 個月後達到：
- 5,000 累積下載
- 1,000 月活躍用戶（MAU）
- 2% 付費轉換率 = 20 付費使用者/月

收入估算：
| 方案 | 人數 | 月收入 |
|------|------|--------|
| 月訂閱 | 10 | $19.9 |
| 年訂閱 | 8 | $9.9（攤平後） |
| Lifetime | 2 | $4.9（攤平後） |
| **合計** | 20 | **~$35/月** |

扣 Apple 30% 後：**~$24/月**

**第二年目標**：MAU 5,000、付費 100 人 → 月淨收入 $120

短期靠 Pro 不會發大財，但比廣告好：
- 不毀 UX
- 不違反隱私承諾
- 隨時間線性成長
- 給重度使用者真實價值

---

## 八、決策里程碑

1. **v1.0 上架** — 純免費，建立評論基礎
2. **+3 個月** — 檢查觸發條件（DAU、評論、需求），決定是否啟動 Pro
3. **v1.3 Pro 上線** — MVP Pro（Tier 1 四項）
4. **+6 個月** — 評估數據，決定 Tier 2 要做哪些
5. **+12 個月** — 決定是否投入 Watch app / Widget

---

## 附錄：開發時數估計

| 功能 | 時數 |
|------|------|
| RevenueCat 整合 + paywall | 8h |
| 進階統計儀表板 | 20h |
| iCloud 同步 | 30h |
| 無限課表 / 動作限制解除 | 4h |
| 進階匯出（PDF、排程） | 12h |
| 行銷素材（paywall 截圖、App Store 更新） | 6h |
| **Tier 1 MVP 合計** | **~80h** |

約 2 週全職 / 2 個月兼職可完成 Pro MVP。
