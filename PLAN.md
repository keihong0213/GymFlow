# GymFlow iOS App — 計劃書 v2

> v1 → v2 主要變更：補完資料模型 schema、新增動作庫設計、PR 定義明確化、
> 新增多語系（zh-Hant / en / ja / ko）策略、單位系統、輸入 UX 細節、
> 測試策略、可用性、MVP 成功標準修正、開發順序細化到 PR 層級。

---

## 1. 產品定位

一個**極簡、超快、不中斷訓練流程**的健身紀錄 App。

### 核心賣點
- 進健身房 **5 秒內開始記第一組**
- 結束後 **10 秒看懂今天表現**
- 不做花俏教練、不做社群、不增加負擔

### 我們**不做**的
- 社群 / 分享 / feed
- AI 教練 / 建議菜單
- 飲食紀錄
- 訂閱制花俏功能（MVP 期間）

---

## 2. 目標使用者

- 重訓新手（需要課表模板帶路）
- 已經有固定課表的中階者（需要快速重複上次）
- 不想被花俏 app 干擾訓練的人
- 想追蹤重量 / 次數 / 組數進步的人

**語言分佈：** 主力為繁體中文使用者，從 day 1 支援 **繁中 / 簡中 / 英 / 日 / 韓** 五語系。

---

## 3. 最大痛點

- 記錄太麻煩、輸入慢
- 每次都要重輸入上次的數字
- App 太多功能反而干擾訓練
- 看得到資料但看不懂進步
- 缺少「上次做了什麼」的快速提示

---

## 4. 產品原則

- **快** — 任何核心操作 ≤ 2 tap
- **少步驟** — 預設帶入上次資料
- **畫面單純** — 一屏一意圖
- **專注訓練，不干擾訓練** — 不推播、不紅點、不彈窗

---

## 5. MVP 功能

### P0（v1.0 上架條件）

1. **訓練紀錄**
   - 動作（從動作庫選 / 自訂）
   - 組數、重量、次數、備註
   - 標記 warm-up vs working set
   - 編輯 / 刪除已輸入的 set

2. **快速重複上次訓練**
   - 開始 workout 時自動帶入上次同動作的重量 / 次數
   - 「上次」preview 顯示在輸入列上方
   - 一鍵複製上一組（常用於同組數連續做）

3. **課表模板**
   - 內建 Push / Pull / Legs / Upper / Lower / Full Body
   - 自訂課表（新增 / 編輯 / 刪除 / 排序）
   - 套用模板開始 workout

4. **動作庫（Exercise Library）**
   - 內建常見動作 seed（約 60–80 個，分 Barbell / Dumbbell / Machine / Bodyweight / Cardio）
   - 動作名稱走 i18n（中 / 英 / 日 / 韓）
   - 搜尋 + 自訂動作
   - 動作分類 filter

5. **訓練完成摘要**
   - 今日總組數、總 volume（∑ 重量 × 次數）
   - 今日是否達成 PR（哪些動作、哪種 PR）
   - 訓練時長

6. **休息計時器**（從 v1 的 P2 提升到 P0）
   - 理由：核心需求，實作簡單
   - 每個動作可設定預設休息秒數
   - 完成一組自動開始倒數、支援背景通知

7. **單位設定**
   - kg / lb 切換（全域）
   - 內部固定以 kg 儲存，顯示時轉換
   - 輸入增減步進：kg → 2.5、lb → 5

8. **多語系**
   - zh-Hant / zh-Hans / en / ja / ko
   - 預設跟隨系統語言；設定內可手動覆蓋

### P1（v1.1–v1.3）

- PR 詳細歷史與圖表
- 每週 / 每月趨勢
- 動作歷史詳情頁
- Apple Health 同步（寫入訓練時長、活動能量）
- 備份 / 還原（JSON / CSV 匯出到 Files）

### P2（未來）

- 圖表分析（per-exercise progression chart）
- iCloud 同步（CloudKit）
- iPad 版面優化
- Apple Watch 快速查看 / 記錄
- Superset / Circuit 支援
- Plate calculator
- Widget（上次訓練摘要）

---

## 6. 使用流程

### 首次開啟（onboarding）

1. 選語言（預設跟隨系統，可改）
2. 選單位（kg / lb；預設依地區推斷）
3. 選擇是否載入內建課表模板（Push/Pull/Legs…）
4. 進入 Home

> 注意：不強制選「目標 / 訓練類型」以縮短 onboarding，這些放在 P1。

### 每次進 gym

1. 開 App → Home
2. 點「開始訓練」→ 選課表（或空白 workout）
3. 按動作列表逐個記錄（預設帶入上次資料）
4. 結束 → 看 Summary

目標：從 App 開啟到第一組記錄完成 **≤ 15 秒**。

---

## 7. 畫面規劃

### 畫面 1: Home
- 上方：今日建議課表（若週期規律）/ 快速開始按鈕
- 中間：上次訓練摘要（日期、動作數、總 volume、是否有 PR）
- 下方：最近 7 天小月曆（有訓練的日期點綴）

### 畫面 2: Routine Picker
- 內建模板列表
- 自訂模板列表
- 「空白 workout」選項

### 畫面 3: Workout Session（最核心）
- 頂部：workout 計時器 + 結束按鈕
- 中間：動作列表（每個動作一個 Section）
  - Section header：動作名稱、上次摘要
  - Rows：已完成組（顯示重量 × 次數）+ 當前輸入列
- 輸入列 UX：
  - 重量欄（tap → 數字鍵盤 + 快速 +2.5 / −2.5 / +5 / −5 按鈕列）
  - 次數欄（tap → 數字鍵盤 + 快速 +1 / −1 / +5 / −5）
  - 「上次」preview 以灰字顯示 placeholder
  - 完成 set 按鈕（大、右側）→ 觸發休息計時器 + haptic
- Long press set → 編輯 / 刪除 / 標記為 warmup / 複製

### 畫面 4: Exercise Detail
- 動作歷史（近期 10 次 workout 的最佳組）
- PR 記錄（Weight PR、Rep PR、估計 1RM）
- 趨勢簡圖（Swift Charts）

### 畫面 5: Templates
- 內建 / 自訂分組
- 新增 / 編輯 / 複製 / 刪除 / 排序

### 畫面 6: Summary
- 日期、時長
- 總 volume、總組數
- 新 PR 列表（若有）
- 下次建議重量（依最後一組表現 +2.5kg 或維持）

### 畫面 7: Settings
- 單位（kg / lb）
- 語言（跟隨系統 / zh-Hant / en / ja / ko）
- 休息計時器預設秒數
- 外觀（自動 / 淺 / 深）
- 備份（P1）
- 關於

---

## 8. 資料模型

所有實體以 Swift `struct` + `Codable` + GRDB 實作。時間戳統一 `Date`（UTC 儲存）。ID 統一 `UUID`。

```swift
// 動作定義（內建或自訂）
struct Exercise {
    let id: UUID
    let slug: String          // i18n key，例如 "bench_press"
    let category: ExerciseCategory   // barbell/dumbbell/machine/bodyweight/cardio
    let isCustom: Bool        // 使用者自訂為 true
    let customName: String?   // 自訂動作顯示名稱（不走 i18n）
    let createdAt: Date
}

// 課表模板
struct Routine {
    let id: UUID
    let name: String          // 自訂模板使用；內建走 i18n
    let slug: String?         // 內建模板的 i18n key
    let isBuiltIn: Bool
    let orderIndex: Int
    let createdAt: Date
}

// 模板中的動作
struct RoutineExercise {
    let id: UUID
    let routineId: UUID
    let exerciseId: UUID
    let orderIndex: Int
    let targetSets: Int?
    let targetRepsMin: Int?
    let targetRepsMax: Int?
    let defaultRestSeconds: Int?
}

// 一次訓練 session
struct Workout {
    let id: UUID
    let startedAt: Date
    let endedAt: Date?
    let routineId: UUID?      // 空白 workout 為 nil
    let notes: String?
}

// workout 中某個動作的 container
struct WorkoutExercise {
    let id: UUID
    let workoutId: UUID
    let exerciseId: UUID
    let orderIndex: Int
    let notes: String?
}

// 一組
struct SetEntry {
    let id: UUID
    let workoutExerciseId: UUID
    let setNumber: Int
    let weightKg: Double       // 固定以 kg 儲存
    let reps: Int
    let isWarmup: Bool
    let rpe: Double?           // P1：1–10，可空
    let completedAt: Date
}

// PR 紀錄（派生 cache，每次新增 set 時重算）
struct PRRecord {
    let id: UUID
    let exerciseId: UUID
    let type: PRType          // .weight / .repsAt(weightKg) / .e1rm
    let valueKg: Double        // weight / e1rm 用；repsAt 用 reps 當 value
    let reps: Int
    let achievedAt: Date
    let workoutExerciseId: UUID
}

// 使用者設定（單列表）
struct UserSettings {
    let units: WeightUnit      // .kg / .lb
    let language: AppLanguage  // .system / .zhHant / .en / .ja / .ko
    let defaultRestSeconds: Int
    let appearance: Appearance // .system / .light / .dark
}
```

### GRDB migrations
- `v1_initial`：建立以上所有 table + 索引
  - `workout_exercise(workout_id, order_index)`
  - `set_entry(workout_exercise_id, set_number)`
  - `pr_record(exercise_id, type)`
- 預留 `migrator.registerMigration("v2_...")` 擴充點

---

## 9. 動作庫 seed（內建約 60–80 個，示意）

以 `slug` 為 key，各語系 display name 放 `Localizable.xcstrings`。

| slug | category | zh-Hant | zh-Hans | en | ja | ko |
|---|---|---|---|---|---|---|
| `bench_press` | barbell | 槓鈴臥推 | 杠铃卧推 | Bench Press | ベンチプレス | 벤치 프레스 |
| `back_squat` | barbell | 背蹲舉 | 背蹲举 | Back Squat | バックスクワット | 백 스쿼트 |
| `deadlift` | barbell | 硬舉 | 硬拉 | Deadlift | デッドリフト | 데드리프트 |
| `overhead_press` | barbell | 肩推 | 肩推 | Overhead Press | オーバーヘッドプレス | 오버헤드 프레스 |
| `pull_up` | bodyweight | 引體向上 | 引体向上 | Pull-Up | 懸垂 | 턱걸이 |
| `lat_pulldown` | machine | 滑輪下拉 | 高位下拉 | Lat Pulldown | ラットプルダウン | 랫 풀다운 |
| `treadmill` | cardio | 跑步機 | 跑步机 | Treadmill | トレッドミル | 트레드밀 |
| ... | ... | ... | ... | ... | ... | ... |

> 完整清單在 PR 1 實作時填滿，初版目標 60 個覆蓋 80% 常見動作。

---

## 10. PR 定義

每個動作追蹤三種 PR：

1. **Weight PR** — 該動作曾舉起的最大重量（至少 1 reps，不計 warmup）
2. **Reps PR at weight W** — 在特定重量 W 下的最大次數（W 以 2.5kg 為桶）
3. **Estimated 1RM (e1RM)** — 用 Epley 公式：`1RM = W × (1 + reps/30)`，取歷來最大

**Summary 畫面顯示：** 只顯示 Weight PR / e1RM PR（避免太吵）；Exercise Detail 完整列。

---

## 11. 多語系策略

### 技術選型
- **String Catalog（`Localizable.xcstrings`）** — Xcode 15+ 官方建議，支援複數、變數、自動抽取
- SwiftUI 直接用 `Text("key")` 或 `String(localized:)`
- 所有使用者可見字串從 day 1 都走 catalog，不允許硬編碼中文

### 支援語言
| Code | 語言 | 備註 |
|---|---|---|
| `zh-Hant` | 繁體中文 | 預設開發語言 |
| `zh-Hans` | 简体中文 | |
| `en` | English | fallback |
| `ja` | 日本語 | |
| `ko` | 한국어 | |

### 切換策略
1. **預設：** 跟隨系統（`Locale.preferredLanguages`）
2. **覆蓋：** Settings 中可強制選語言，寫入 `UserDefaults` 並透過 `Bundle` swizzle 或 `AppStorage + .environment(\.locale, …)` 實作 runtime 切換
3. **Fallback：** 若系統語言不在支援清單，fallback 到英文

### 動作庫多語系
- 內建動作：`slug` 當 i18n key，放 `Localizable.xcstrings`（例如 `exercise.bench_press.name`）
- 自訂動作：存 `customName` 欄位（使用者自己負責語言）

### 日期 / 數字 / 單位格式
- 用 `Date.FormatStyle` / `Measurement<UnitMass>` 依 locale 格式化
- 重量顯示用 `Measurement`（e.g. `85.0 kg` vs `187 lb`）

### 測試
- Unit test 覆蓋 `WeightFormatter` 四語系各一個 case
- Preview 上 `.environment(\.locale, Locale(identifier: "ja"))` 快速驗證

---

## 12. 輸入 UX 細節

### Set 輸入列
```
┌────────────────────────────────────────────┐
│ Set 3    [ 85.0 kg ]  ×  [ 8 ]       [ ✓ ] │
│          ↑ tap                             │
│          ┌─────────────────────┐           │
│          │ −5  −2.5  +2.5  +5  │           │
│          │   [ number keypad ] │           │
│          └─────────────────────┘           │
└────────────────────────────────────────────┘
上次：85.0 × 8
```

- 輸入欄 tap → 顯示自訂 keypad（替代系統數字鍵盤，能塞快速按鈕）
- 完成按鈕（✓）大、觸覺回饋、自動進入下一組
- 長按 set row → action sheet（編輯 / 刪除 / 標 warmup / 複製）
- Warmup sets 用灰色字體 + 左側 ◦ 記號區分

### 快速操作
- 空白 set 自動用上次同 setNumber 的值當預設
- 「重做上一組」button：一鍵複製上一組數字（訓練中最常用）

---

## 13. 技術棧與架構

- **UI：** SwiftUI（最低 iOS 17）
- **Observability：** `@Observable` macro（iOS 17+）
- **Navigation：** `NavigationStack` + typed path
- **資料庫：** GRDB.swift（SQLite）
- **圖表：** Swift Charts（內建）
- **架構：** MVVM（View ↔ ObservableViewModel ↔ Repository ↔ GRDB）
- **DI：** 建構子注入，避免 singleton（除了 AppDatabase）
- **模組切分：**
  - `App/` — entry、AppDelegate
  - `Features/Home`、`Features/Workout`、`Features/Templates`、`Features/ExerciseDetail`、`Features/Summary`、`Features/Settings`
  - `Core/Database`（GRDB 設定、migrations）
  - `Core/Models`（Swift structs）
  - `Core/Repositories`（`WorkoutRepository`、`ExerciseRepository`…）
  - `Core/Services`（`PRCalculator`、`RestTimer`、`WeightFormatter`）
  - `Resources/Localizable.xcstrings`、`SeedData/exercises.json`

### 最低 iOS 版本
**iOS 17.0** — 理由：`@Observable` 乾淨、String Catalog 最佳體驗、SwiftUI navigation 穩定；2026 年 iOS 17 已覆蓋 >90% 活躍裝置。

---

## 14. 測試策略

- **Unit Tests（P0 必做）：**
  - `PRCalculator`：Weight PR / Reps PR / e1RM
  - `WeightFormatter`：kg↔lb 轉換、四語系 locale
  - `RoutineRepository`：CRUD
  - GRDB migrations（up）
- **Snapshot Tests（P1）：** 關鍵畫面 × 4 語系 × 深淺色
- **UI Tests（P1）：** onboarding → 開始 workout → 完成 1 組 → 結束 → Summary

---

## 15. 無障礙與外觀

- **Dark mode：** 預設跟隨系統，Settings 可覆蓋
- **Dynamic Type：** 所有文字 scale，核心按鈕最少 44pt
- **VoiceOver：** 所有按鈕、輸入列有 label；set row 的 accessibilityValue 念出「重量 X 次數 Y」
- **Haptics：** 完成 set、休息倒數結束、達成 PR
- **Reduce Motion：** 尊重系統設定

---

## 16. 備份 / 匯出（P1）

- JSON 匯出（完整）與 CSV 匯出（per-workout）
- 寫到 Files app / AirDrop 分享
- P2：加密備份、iCloud

---

## 17. MVP 成功標準（修正）

| 指標 | 目標 |
|---|---|
| App 開啟到第一組記錄完成 | ≤ 15 秒 |
| 單組記錄（輸入重量 + 次數 + 完成） | ≤ 5 秒 |
| 看上次同動作的數字 | 0 額外操作（自動帶入） |
| 結束 workout 到看懂 Summary | ≤ 10 秒 |
| Crash-free rate | ≥ 99.5% |
| 五語系 UI 無截斷 / 無英文外洩 | 100% |

---

## 18. 開發順序（PR 層級）

| # | PR | 產出 | 測試 |
|---|---|---|---|
| 1 | 資料層 | GRDB 設定、所有 table migration、Swift models、基本 repositories | Model + Migration unit tests |
| 2 | 多語系 scaffold | `Localizable.xcstrings` 建立、5 語系樣板、`LanguageManager`、Settings 切換 | Locale 切換 preview OK |
| 3 | 動作庫 seed | `exercises.json` + loader、首次啟動 seed 60 個動作 + 5 語系名稱 | Seed idempotent test |
| 4 | Home 畫面 | 上次訓練摘要、快速開始 button、最近 7 天 | Preview × 4 語系 |
| 5 | Workout Session（核心） | 動作列表、set 輸入 UX、休息計時器、上次帶入、編輯/刪除 set | ViewModel unit tests |
| 6 | 課表模板 | 內建 PPL 模板、CRUD 自訂模板 | Template repository tests |
| 7 | Summary + PR 偵測 | `PRCalculator`、Summary 畫面、新 PR highlight | PR calculator unit tests |
| 8 | Exercise Detail | 歷史列表、PR 列表、Swift Charts 趨勢圖 | Snapshot 1 語系 |
| 9 | Settings | 單位、語言、休息預設、外觀 | 手動 QA |
| 10 | Polish & a11y | VoiceOver labels、Dynamic Type、haptics、icon、onboarding | UI test golden path |
| 11 | TestFlight beta | Crash reporting、Analytics（minimal） | — |

> 每個 PR 結束需可 build、可在 simulator 跑、既有功能不 regress。

---

## 19. 風險與開放問題

- **GRDB 還是 SwiftData？** 選 GRDB — 理由：migrations 可控、query 清楚、SwiftData 在 iOS 17 早期 API 不穩。若未來 SwiftData 穩定可評估遷移。
- **休息計時器背景通知** — 需要 `UNUserNotificationCenter` 權限，onboarding 流程中要不要提前請求？→ **決策：不提前請求，第一次完成 set 時才問。**
- **語言偵測範圍** — 只偵測系統「主要語言」；若主要語言非支援範圍，fallback en。
- **動作庫 seed 更新** — 未來要加動作怎麼辦？→ migration 帶新 seed + upsert by slug。
- **PR 計算效能** — 每次完成 set 就重算會不會慢？→ 只重算該動作、非全部，且在 background task，可接受。

---

## 20. 下一步

批准此計劃 → 開 PR 1（資料層 + GRDB + migrations + seed loader + unit tests）。
