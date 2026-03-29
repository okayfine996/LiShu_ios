# LiShu Agent Team 开发提示词

> 复制以下内容到 Claude Code 中启动 Agent Team 开发

---

## 提示词

请用 Agent Team 模式开发 LiShu（礼数）iOS App 的 Phase 1 MVP。

### 项目背景

这是一款人情往来记账 iOS 应用，使用 SwiftUI + SwiftData 构建。项目已有：
- **设计系统**: `LiShu/DesignSystem/DesignTokens.swift` — 所有 UI 必须使用 `DesignSystem.*` 令牌
- **开发规范**: `CLAUDE.md` — MVVM 架构、文件组织、View 拆分、导航路由、SwiftData 数据层、错误处理规范
- **产品需求**: `PRD.md` — 完整 PRD，本次只做 Phase 1 的 P0 功能
- **UI 设计**: Stitch 项目 `4174518520668530705` — 包含所有页面的 UI 设计稿，使用 Stitch MCP 的 `get_screen` 获取对应页面 HTML 作为实现参考

### Stitch UI 设计稿索引

以下是各模块对应的 Stitch 屏幕 ID，开发时通过 `mcp__stitch__get_screen` 获取 HTML 参考：

| 模块 | 屏幕名称 | Screen ID |
|------|---------|-----------|
| 首页 | 首页 - 中文语言统一 | `b88d7271d1494648aae5903708953a5d` |
| 记录 | 记录列表 - 胶囊形状分段器 | `caa936eeac324eb2a7de578621e5f267` |
| 记录 | Add Gift Record (往来录入) | `7b990ad4c3874f04a40945d3c90eae4b` |
| 记录 | 交易详情 - 明确收/送性质 | `63c0dfd7823d4756ae6c54a1b791f34b` |
| 记录 | 按月往来详情 | `47221cc07fec4036a26b0b91d6ab1e0f` |
| 联系人 | Contacts List (人脉) | `bb0343db3ec94a62a4f73efbf50983e7` |
| 联系人 | Contact Details (联系人详情) | `e74491f582134d23a3dbf0833dfdd5ce` |
| 联系人 | Create New Contact (新建联系人) | `0296bf021cbf4f8aa8ce5aa8042fa563` |
| 事件 | 事件列表 - 卡片样式修正 | `a321007a2602435e990695248569ee11` |
| 事件 | Create New Event (新建事件) | `773e5a92a67344e6872246dd140b800a` |
| 统计 | 统计概览(上半) | `7dd6b87753a5458f83ee2ce8ec018099` |
| 统计 | 统计概览(下半) | `14fd66597e6a4c80acfc23842a50629f` |
| 统计 | Net Value Ranking (往来排行) | `a701ac6a48e94ad4be8164f1c4888a16` |
| 设置 | 设置 (已开通 Pro) | `0d2e561d00e847cfa756660173cd7697` |
| 设置 | 外观风格设置 | `bb8a4df0833a482e81044e785d2322ec` |
| 设置 | 通知管理设置 | `ab0ebbbed8674359a9f5d159117aa9c4` |
| 设置 | 隐私设置 | `d3eb3c947cb141dd9080718c4984afc4` |
| 设置 | 导入与导出设置 | `1b5a257a3c6c42c987cc8e768f617d6c` |
| 设置 | 关于礼数 | `2fecdfd8ec184d60bef28012f1b90cbd` |
| 设置 | 删除所有数据确认页 | `228a73d6a872466b9c182982a5af7840` |
| 设置 | 清除缓存确认弹窗 | `b283289fc6004523a9462af8a7eb43d5` |

> **使用方法**: `mcp__stitch__get_screen(projectId: "4174518520668530705", screenId: "<ID>", name: "projects/4174518520668530705/screens/<ID>")`，然后通过 WebFetch 获取返回的 `htmlCode.downloadUrl` 查看 UI 细节。

---

### Phase 1 P0 开发范围

#### 1. SwiftData 数据模型层 (Models/)

##### Contact.swift — 联系人
```swift
@Model final class Contact {
    var name: String                    // 姓名 (必填)
    var phone: String                   // 电话
    @Attribute(.externalStorage)
    var avatar: Data?                   // 头像图片 (外部存储, iCloud 同步)
    var relation: String                // 关系标签 (如 "父亲"/"大学同学")
    var category: String                // 关系分类 (家人/亲属/社交/其他)
    var circle: Int                     // 亲密圈层 (1=家人, 2=亲属, 3=社交, 4=其他)
    var birthday: Date?                 // 生日
    var location: String                // 地区
    var note: String                    // 备注
    @Relationship(deleteRule: .cascade, inverse: \Record.contact)
    var records: [Record] = []
    var createdAt: Date
}
```

##### Record.swift — 礼金记录
```swift
@Model final class Record {
    var contact: Contact?               // 关联联系人
    var event: Event?                   // 关联事件
    var amount: Double                  // 金额 (正数)
    var direction: RecordDirection      // .given(随礼) / .received(收礼)
    var paymentMethod: PaymentMethod    // .cash/.wechat/.alipay/.item
    var returnedAmount: Double           // 已退礼金额
    @Relationship(deleteRule: .cascade, inverse: \RecordPhoto.record)
    var photos: [RecordPhoto] = []      // 附属照片（留念照等）
    var note: String                    // 备注
    var date: Date                      // 日期
    var status: RecordStatus            // .open(有效敞口)/.partial(部分退礼)/.settled(已结清)
    var createdAt: Date
}

enum RecordDirection: String, Codable, CaseIterable {
    case given = "given"     // 随礼（我送出）
    case received = "received" // 收礼（我收到）
}

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "cash"        // 现金
    case wechat = "wechat"    // 微信
    case alipay = "alipay"    // 支付宝
    case item = "item"        // 实物
}

enum RecordStatus: String, Codable, CaseIterable {
    case open = "open"        // 有效敞口 🔴
    case partial = "partial"  // 部分退礼 🟡
    case settled = "settled"  // 已结清 🟢
}
```

**状态机逻辑**:
- 新记录默认 `.open`
- 退礼金额 > 0 且 < 原金额 → `.partial`
- 退礼金额 ≥ 原金额 → `.settled`
- 实际人情负债 = 金额 - 退礼金额

##### Event.swift — 事件
```swift
@Model final class Event {
    var name: String                    // 事件名称
    var type: EventType                 // 事件类型
    var date: Date                      // 日期
    var location: String                // 地点
    var notes: String                   // 备注
    @Relationship(deleteRule: .nullify, inverse: \Record.event)
    var records: [Record] = []
    var createdAt: Date
}

enum EventType: String, Codable, CaseIterable {
    case wedding = "wedding"            // 结婚大喜
    case funeral = "funeral"            // 丧葬白事
    case birth = "birth"               // 满月百天
    case birthday = "birthday"         // 生日寿宴
    case festival = "festival"         // 节庆往来
    case property = "property"         // 乔迁新居
    case education = "education"       // 升学谢师
    case other = "other"               // 其他
}
```

##### Family.swift — 家庭核算单元
```swift
@Model final class Family {
    var name: String                    // 家庭名称 (如 "张三一家")
    @Relationship(deleteRule: .nullify)
    var members: [Contact] = []
    var createdAt: Date
}
```

**关键约束**:
- 所有 `@Relationship` 必须设置 `deleteRule` 和 `inverse`
- Model 中不放 UI/SwiftUI 逻辑
- enum 全部实现 `Codable` + `CaseIterable`

---

#### 2. 导航 & App 骨架 (Navigation/, App/)

##### 底部 Tab 导航 — 5 个 Tab

```
┌─────┬─────┬─────┬─────┬─────┐
│ 首页 │ 账本 │ 人脉 │ 统计 │ 我的 │
│house│doc. │pers │chart│pers │
│.fill│text │on.2 │.bar │on   │
└─────┴─────┴─────┴─────┴─────┘
```

- **首页** — SF Symbol: `house.fill` — HomeView
- **账本** — SF Symbol: `doc.text` — RecordListView
- **人脉** — SF Symbol: `person.2.fill` — ContactListView
- **统计** — SF Symbol: `chart.bar.fill` — StatisticsView
- **我的** — SF Symbol: `person.fill` — SettingsView

每个 Tab 有独立 `NavigationStack`。

##### AppRouter.swift — 路由枚举
```swift
enum AppRoute: Hashable {
    // 记录
    case recordDetail(Record)
    case addRecord(direction: RecordDirection?, contact: Contact?)
    case monthlyDetail(year: Int, month: Int)
    // 联系人
    case contactDetail(Contact)
    case addContact
    // 事件
    case eventList
    case eventDetail(Event)
    case addEvent
    // 统计
    case netValueRanking
    // 设置子页
    case appearanceSettings
    case notificationSettings
    case securitySettings
    case dataManagement
    case importExport
    case about
}
```

##### LiShuApp.swift
- 创建 `ModelContainer`（注册 Contact, Record, Event, Family）
- 注入 `.modelContainer()` 到根视图
- 根视图为 `MainTabView`

---

#### 3. 首页模块 (Views/Home/)

**对应 Stitch 屏幕**: `b88d7271d1494648aae5903708953a5d`

##### HomeView.swift — 首页仪表盘

```
┌────────────────────────────────────┐
│ 你好，用户          📋 (通知铃铛)    │  ← 顶部问候栏
│ 2025年3月1日                        │
├────────────────────────────────────┤
│ ┌──2025年账本摘要──────────────────┐ │
│ │  收入        支出        人数    │ │  ← 年度摘要卡片
│ │ ¥12,000    ¥8,500      38人    │ │
│ └──────────────────────────────────┘ │
├────────────────────────────────────┤
│ 即将到来                    查看全部 │  ← 即将到来事件
│ ┌──────────────────────────────────┐ │
│ │ 🎊 表妹婚礼  10月24日     >     │ │
│ │ 🎂 生日宴    11月2日      >     │ │
│ └──────────────────────────────────┘ │
├────────────────────────────────────┤
│ 最近记录                    查看全部 │  ← 最近往来记录
│ ┌──────────────────────────────────┐ │
│ │ 😊 张三  结婚随礼  +¥500  今天  │ │
│ │ 😊 李四  生日红包  -¥200  昨天  │ │
│ └──────────────────────────────────┘ │
└────────────────────────────────────┘
```

**UI 要点**:
- 顶部显示问候语 + 当前日期
- 年度摘要卡片: 总收入/总支出/往来人数，bgCard 背景 + card 圆角
- "即将到来" section: 近期事件列表，点击进入事件详情
- "最近记录" section: 最近 5 条往来记录，点击进入记录详情
- 金额颜色: 收入(+)用绿色系, 支出(-)用 primary 赤陶色
- 页面底部留 Tab 安全区

##### HomeViewModel.swift
- 计算年度总收入/总支出/往来人数
- 查询最近 5 条记录
- 查询即将到来的事件（按日期排序，取最近 3-5 条）

---

#### 4. 记录模块 (Views/Records/)

##### RecordListView.swift — 记录列表

**对应 Stitch 屏幕**: `caa936eeac324eb2a7de578621e5f267`

```
┌────────────────────────────────────┐
│ 记录列表              🔍  ≡(筛选)  │  ← 导航栏
├────────────────────────────────────┤
│ ┌──全部──┬──随礼──┬──收礼──┐      │  ← 胶囊分段器
│ └────────┴────────┴────────┘      │
├────────────────────────────────────┤
│ 2025年6月                          │  ← 月份分组标题
│ ┌──────────────────────────────────┐ │
│ │ 👩 李梅    结婚随礼              │ │
│ │    6月24日          + ¥800 待还礼│ │  ← RecordRow
│ ├──────────────────────────────────┤ │
│ │ 👨 陈伟    满月酒                │ │
│ │    6月15日          - ¥2,000 已完成│ │
│ └──────────────────────────────────┘ │
│ 2025年5月                          │
│ ┌──────────────────────────────────┐ │
│ │ 👩 王芳    升职宴请              │ │
│ │    5月15日          - ¥500 已收礼│ │
│ └──────────────────────────────────┘ │
│                            ⊕ (FAB)  │  ← 浮动添加按钮
└────────────────────────────────────┘
```

**UI 要点**:
- 顶部胶囊分段器 (Capsule SegmentedControl): **全部 / 随礼 / 收礼**
- 列表按月份分组，月份标题粗体
- RecordRow 每行: emoji头像 + 姓名 + 事件类型 + 日期 + 金额 + 状态标签
- 金额格式: `+ ¥800` (绿色,收礼) / `- ¥2,000` (赤陶色,随礼)
- **状态标签** (StatusBadge):
  - `待还礼` — 🔴 bgTag 背景 + primary 文字 (有效敞口)
  - `已收礼` — 🟡 bgTag + textSecondary
  - `已完成` — 🟢 bgTag + green tint
- 左滑操作: **编辑** / **删除**
- 右下角 FAB 浮动按钮，点击进入 AddRecordView
- 顶部搜索 + 筛选按钮

##### AddRecordView.swift — 新增记录（往来录入）

**对应 Stitch 屏幕**: `7b990ad4c3874f04a40945d3c90eae4b`

```
┌────────────────────────────────────┐
│ ✕ 往来录入                   保存   │  ← Sheet 导航栏
├────────────────────────────────────┤
│    ┌──随礼──┬──收礼──┐             │  ← 收/送切换 (胶囊Toggle)
│    └────────┴────────┘             │
├────────────────────────────────────┤
│ 送给 / 来自                         │  ← 标签随切换变化
│ ┌──────────────────────────────────┐ │
│ │ 😊 李明        选择联系人 >      │ │  ← 联系人选择器
│ └──────────────────────────────────┘ │
├────────────────────────────────────┤
│ 🎉 事件类型                         │
│ ┌────────────────────────────────┐  │
│ │ 结婚大喜              ∨       │  │  ← 下拉选择
│ └────────────────────────────────┘  │
│ 事件选项: 结婚大喜/生日寿宴/满月百天/ │
│          乔迁新居/升学谢师/其他      │
├────────────────────────────────────┤
│ ¥ 金额                              │
│ ┌────────────────────────────────┐  │
│ │          ¥ 0                   │  │  ← 金额输入
│ └────────────────────────────────┘  │
│ 💡 建议参考：¥600 - ¥1000           │  ← 随礼时显示建议
├────────────────────────────────────┤
│ 支付方式                             │
│ ┌──现金──┬──微信──┬──支付宝──┐      │  ← 3选1
│ └────────┴────────┴──────────┘      │
├────────────────────────────────────┤
│ 📅 日期  2025年3月1日               │  ← DatePicker
├────────────────────────────────────┤
│ 📝 备注与图片            📷         │  ← 文本 + 图片
│ ┌────────────────────────────────┐  │
│ │ 输入备注...                    │  │
│ └────────────────────────────────┘  │
├────────────────────────────────────┤
│ ┌────────────────────────────────┐  │
│ │         确认随礼 / 确认收礼     │  │  ← PrimaryButton
│ └────────────────────────────────┘  │
└────────────────────────────────────┘
```

**UI 要点**:
- 以 `.sheet` 方式弹出
- 顶部 **随礼/收礼** 胶囊 Toggle — 切换后:
  - 标签 "送给" ↔ "来自"
  - 按钮文案 "确认随礼" ↔ "确认收礼"
- 联系人选择器: 点击跳转联系人选取页 (或内嵌搜索列表)
- 事件类型: 下拉菜单/Picker，选项: 结婚大喜/生日寿宴/满月百天/乔迁新居/升学谢师/丧葬白事/节庆往来/其他
- 金额输入: 数字键盘，¥ 前缀
- 支付方式: 3 个胶囊按钮单选 (现金/微信/支付宝)
- 日期选择器: 默认今天
- 备注 + 图片上传 (Phase 1 图片功能可占位)
- 底部确认按钮用 `PrimaryButtonStyle()`

##### RecordDetailView.swift — 记录详情

**对应 Stitch 屏幕**: `63c0dfd7823d4756ae6c54a1b791f34b`

```
┌────────────────────────────────────┐
│ ← 交易详情               编辑 删除  │
├────────────────────────────────────┤
│       ┌──送出──┐ or ┌──收到──┐     │  ← 方向标签
│       └────────┘    └────────┘     │
│           ¥ 2,000                  │  ← 大字号金额
│       状态: 待还礼 🔴               │
├────────────────────────────────────┤
│ 联系人   👩 李梅  亲戚 · 表姐       │
│ 事件     🎊 结婚大喜               │
│ 日期     📅 2025年6月24日          │
│ 支付方式  💳 微信支付               │
│ 备注     📝 新婚快乐               │
├────────────────────────────────────┤
│ 退礼记录                           │
│ ┌──────────────────────────────────┐ │
│ │ 退礼金额: ¥0    [记录退礼]      │ │  ← 退礼操作入口
│ │ 实际负债: ¥2,000                 │ │
│ └──────────────────────────────────┘ │
└────────────────────────────────────┘
```

**退礼流程**: 点击"记录退礼"→弹出退礼金额输入→保存后:
- 更新 `returnedAmount`
- 自动重算 status (partial/settled)
- 刷新联系人净值

##### RecordListViewModel.swift
- 按月分组查询记录
- 支持按 direction 筛选 (全部/随礼/收礼)
- 搜索 (按联系人名/事件名)
- 删除记录

---

#### 5. 联系人模块 (Views/Contacts/)

##### ContactListView.swift — 联系人列表 (人脉)

**对应 Stitch 屏幕**: `bb0343db3ec94a62a4f73efbf50983e7`

```
┌────────────────────────────────────┐
│ 人脉 (142)           🔍  ➕  📤   │  ← 导航栏 (总人数 + 搜索/添加/分享)
├────────────────────────────────────┤
│ ┌全部─┬直系─┬近亲─┬社会─┐          │  ← 圈层筛选 Tab
│ └─────┴─────┴─────┴─────┘          │
├────────────────────────────────────┤
│ 直系亲属                            │  ← 分组标题
│ ┌──────────────────────────────────┐ │
│ │ 😊 张父    父亲    净额 +¥3,200 │ │  ← ContactRow
│ │ 😊 李母    母亲    净额 -¥1,500 │ │
│ └──────────────────────────────────┘ │
│ 好友同事                            │
│ ┌──────────────────────────────────┐ │
│ │ 😊 王五    大学同学  净额 +¥800  │ │
│ │ 😊 赵六    同事    净额 -¥500   │ │
│ └──────────────────────────────────┘ │
└────────────────────────────────────┘
```

**UI 要点**:
- 导航栏: 标题 "人脉" + 括号总人数 + 搜索/添加/分享按钮
- **圈层筛选** Tab: 全部 / 直系 / 近亲 / 社会
- 按 `relationCategory` 分组，组标题加粗
- ContactRow: emoji头像 + 姓名 + 关系标签 + 净额 (正绿/负赤陶色)
- 搜索栏: 支持按姓名/关系标签搜索
- 点击进入 ContactDetailView

##### ContactDetailView.swift — 联系人详情

**对应 Stitch 屏幕**: `e74491f582134d23a3dbf0833dfdd5ce`

```
┌────────────────────────────────────┐
│ ←                          编辑    │
├────────────────────────────────────┤
│              😊                     │
│            张三                     │  ← 大头像 + 姓名
│        亲戚 · 表哥                  │  ← 关系标签
│        北京市朝阳区                  │  ← 地区
├────────────────────────────────────┤
│ ┌────┬────┬────┬────┐              │
│ │随礼 │收礼 │退礼 │净额 │              │  ← 4 个 StatCard
│ │¥2500│¥1200│¥500│+¥800│              │
│ └────┴────┴────┴────┘              │
├────────────────────────────────────┤
│ ┌──详情──┬──备注──┐                 │  ← Tabs
│ └────────┴────────┘                 │
│ 个人信息                            │
│ 🎂 生日     1990年5月15日           │
│ 👥 圈层     近亲                    │
│ 📱 电话     138****1234            │
├────────────────────────────────────┤
│ 往来记录                            │
│ ┌──────────────────────────────────┐ │
│ │ 🎊 结婚随礼  +¥800  2025.06.24 │ │
│ │ 🎂 生日红包  -¥500  2024.11.02  │ │
│ └──────────────────────────────────┘ │
└────────────────────────────────────┘
```

**UI 要点**:
- 顶部大头像 (emoji) + 姓名 + 关系标签 + 地区
- **4 个财务统计卡片** (2x2 网格):
  - 随礼 (arrow_upward icon) — 我送给对方的总额
  - 收礼 (arrow_downward icon) — 对方送给我的总额
  - 退礼 (replay icon) — 退回的总额
  - 净额 (account_balance_wallet icon) — 净往来 (正数=对方欠我，负数=我欠对方)
- Tab 切换: **详情** / **备注**
- 详情 Tab: 生日、圈层、电话等个人信息
- 往来记录: 该联系人所有历史记录列表
- 净额颜色: 正数绿色，负数赤陶色

##### AddContactView.swift — 新建联系人

**对应 Stitch 屏幕**: `0296bf021cbf4f8aa8ce5aa8042fa563`

```
┌────────────────────────────────────┐
│ ← 新建联系人                        │
├────────────────────────────────────┤
│          ┌─────┐                    │
│          │ 📷  │                    │  ← 头像选择 (emoji)
│          └─────┘                    │
├────────────────────────────────────┤
│ 姓名 *                              │
│ ┌────────────────────────────────┐  │
│ │ 请输入姓名                      │  │
│ └────────────────────────────────┘  │
│ 关系类型 *                           │
│ ┌────────────────────────────────┐  │
│ │ 请选择关系类型            ∨    │  │  ← 关系大类选择
│ └────────────────────────────────┘  │
│ 具体关系                             │
│ ┌────────────────────────────────┐  │
│ │ 请选择具体关系            ∨    │  │  ← 关系标签选择
│ └────────────────────────────────┘  │
│ 生日                                 │
│ ┌────────────────────────────────┐  │
│ │ 选择日期                  📅   │  │
│ └────────────────────────────────┘  │
│ 电话                                 │
│ ┌────────────────────────────────┐  │
│ │ 请输入电话        [从通讯录导入]│  │
│ └────────────────────────────────┘  │
│ 核算单位                             │
│ ┌────────────────────────────────┐  │
│ │ 可选: 绑定家庭单元        ∨   │  │
│ └────────────────────────────────┘  │
│ 备注                                 │
│ ┌────────────────────────────────┐  │
│ │ 输入备注...                    │  │
│ └────────────────────────────────┘  │
├────────────────────────────────────┤
│ ┌────────────────────────────────┐  │
│ │          保存联系人             │  │  ← PrimaryButton
│ └────────────────────────────────┘  │
└────────────────────────────────────┘
```

**关系标签体系** (内置差序格局字典):
```
直系: 父亲/母亲/配偶/儿子/女儿/兄弟/姐妹
近亲: 祖父/祖母/外公/外婆/伯父/叔叔/姑姑/舅舅/姨妈/堂兄弟/堂姐妹/表兄弟/表姐妹/侄子/侄女/外甥/外甥女
姻亲: 公公/婆婆/岳父/岳母/大伯/小叔/弟媳/嫂子
社会-地缘: 同村/同乡/邻居
社会-业缘: 同事/生意伙伴/客户/上级/下属
社会-学缘: 小学同学/初中同学/高中同学/大学同学/研究生同学
社会-特殊: 发小/战友/师傅/徒弟
自定义: (用户自行输入)
```

**UI 要点**:
- 表单字段全部使用 `StandardTextFieldStyle()`
- 关系类型选择器: 先选大类 (直系/近亲/姻亲/社会)，再选具体标签
- 电话字段: 支持 "从通讯录导入" 按钮
- 核算单位: 可选绑定 Family
- 所有输入框 `bgInput` 背景 + 12pt 圆角

##### ContactListViewModel.swift
- 按圈层筛选 + 搜索
- 计算每个联系人的净额
- 按分组排序

---

#### 6. 事件模块 (Views/Events/)

##### EventListView.swift — 事件列表

**对应 Stitch 屏幕**: `a321007a2602435e990695248569ee11`

```
┌────────────────────────────────────┐
│ ← 事件列表                    ➕   │
├────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │
│ │ 🎊 表妹婚礼                     │ │
│ │ 结婚大喜 · 2025年10月24日        │ │  ← 事件卡片
│ │ 📍 北京市 · 共 5 条记录          │ │
│ └──────────────────────────────────┘ │
│ ┌──────────────────────────────────┐ │
│ │ 🎂 爸爸60大寿                    │ │
│ │ 生日寿宴 · 2025年8月15日         │ │
│ │ 📍 老家 · 共 12 条记录           │ │
│ └──────────────────────────────────┘ │
└────────────────────────────────────┘
```

##### AddEventView.swift — 新建事件

**对应 Stitch 屏幕**: `773e5a92a67344e6872246dd140b800a`

```
┌────────────────────────────────────┐
│ ← 新建事件                          │
├────────────────────────────────────┤
│ 事件名称 *                           │
│ ┌────────────────────────────────┐  │
│ │ 请输入事件名称                  │  │
│ └────────────────────────────────┘  │
├────────────────────────────────────┤
│ 事件类型 *                           │
│ ┌────┬────┬────┐                   │
│ │ 🎊 │ 🎂 │ 🕯 │                   │
│ │婚礼 │生日 │丧葬 │                   │  ← 3x2 图标网格
│ ├────┼────┼────┤                   │
│ │ 👶 │ 🏠 │ 🎓 │                   │
│ │满月 │乔迁 │升学 │                   │
│ └────┴────┴────┘                   │
├────────────────────────────────────┤
│ 日期 *                               │
│ ┌────────────────────────────────┐  │
│ │ 选择日期                  📅   │  │
│ └────────────────────────────────┘  │
│ 地点                                 │
│ ┌────────────────────────────────┐  │
│ │ 请输入地点                      │  │
│ └────────────────────────────────┘  │
│ 备注                                 │
│ ┌────────────────────────────────┐  │
│ │ 输入备注...                    │  │
│ └────────────────────────────────┘  │
├────────────────────────────────────┤
│ ┌────────────────────────────────┐  │
│ │          保存事件               │  │
│ └────────────────────────────────┘  │
└────────────────────────────────────┘
```

**事件类型网格** (3x2): 每个带 emoji 图标 + 中文标签
- 🎊 婚礼 | 🎂 生日 | 🕯 丧葬
- 👶 满月 | 🏠 乔迁 | 🎓 升学

---

#### 7. 统计模块 (Views/Statistics/)

##### StatisticsView.swift — 统计概览

**对应 Stitch 屏幕**: `7dd6b87753a5458f83ee2ce8ec018099` + `14fd66597e6a4c80acfc23842a50629f`

```
┌────────────────────────────────────┐
│ 统计概览                            │
├────────────────────────────────────┤
│ ┌──2025──┬──2024──┬──2023──┐       │  ← 年份选择器 (横向滚动)
│ └────────┴────────┴────────┘       │
├────────────────────────────────────┤
│ 年度总览                            │
│ ┌────┬────┬────┐                   │
│ │总收入│总支出│净值 │                   │  ← 3 个 StatCard
│ │¥12K │¥8.5K│+¥3.5K│                  │
│ └────┴────┴────┘                   │
├────────────────────────────────────┤
│ 月度趋势              ← 横向滚动 → │
│ ┌────┬────┬────┬────┐              │  ← 月度卡片 HScroll
│ │1月  │2月  │3月  │...  │              │
│ │+¥2K │-¥1K │+¥3K │     │              │
│ └────┴────┴────┴────┘              │
├────────────────────────────────────┤
│ 事件类型分布                         │
│ ┌──────────────────────────────────┐ │
│ │ 🎊 婚礼  45%   ████████████    │ │
│ │ 🎂 生日  25%   ██████          │ │  ← 事件类型占比
│ │ 🏠 乔迁  15%   ████            │ │
│ │ 其他    15%   ████            │ │
│ └──────────────────────────────────┘ │
├────────────────────────────────────┤
│ 往来排行                    查看全部 │  ← 进入 NetValueRanking
│ ┌──────────────────────────────────┐ │
│ │ 1. 张三  +¥3,200  38次往来      │ │
│ │ 2. 李四  -¥1,500  22次往来      │ │
│ │ 3. 王五  +¥800   15次往来       │ │
│ └──────────────────────────────────┘ │
└────────────────────────────────────┘
```

##### NetValueRankingView.swift — 往来净值排行

**对应 Stitch 屏幕**: `a701ac6a48e94ad4be8164f1c4888a16`

```
┌────────────────────────────────────┐
│ ← 往来排行                          │
├────────────────────────────────────┤
│ ┌往来最多┬收入最高┬支出最高┐         │  ← 3 个筛选 Tab
│ └────────┴────────┴────────┘         │
├────────────────────────────────────┤
│ 1  😊 张三    38次   净额 +¥3,200  │
│ 2  😊 李四    22次   净额 -¥1,500  │
│ 3  😊 王五    15次   净额 +¥800    │
│ ...                                │
└────────────────────────────────────┘
```

##### StatisticsViewModel.swift
- 按年份查询统计数据
- 计算月度收支
- 事件类型占比
- 往来排行 (按净额/收入/支出排序)

---

#### 8. 设置模块 (Views/Settings/)

##### SettingsView.swift — 设置首页（我的）

**对应 Stitch 屏幕**: `0d2e561d00e847cfa756660173cd7697`

```
┌────────────────────────────────────┐
│ 我的                                │
├────────────────────────────────────┤
│ ┌──Pro 会员卡片 (渐变背景)──────────┐ │
│ │ 🏅 礼数 Pro                      │ │  ← Pro 推广卡片
│ │ 解锁全部高级功能                   │ │     (proGradient)
│ │                   [立即开通]      │ │
│ └──────────────────────────────────┘ │
├────────────────────────────────────┤
│ 外观与显示                           │
│ ┌──────────────────────────────────┐ │
│ │ 🎨 外观风格                  >  │ │
│ └──────────────────────────────────┘ │
│ 通知管理                             │
│ ┌──────────────────────────────────┐ │
│ │ 🔔 通知设置                  >  │ │
│ └──────────────────────────────────┘ │
│ 安全与隐私                           │
│ ┌──────────────────────────────────┐ │
│ │ 🔒 隐私设置                  >  │ │
│ └──────────────────────────────────┘ │
│ 数据管理                             │
│ ┌──────────────────────────────────┐ │
│ │ 📥 导入与导出                >  │ │
│ │ 🗑 清除缓存                  >  │ │
│ │ ⚠️ 删除所有数据               >  │ │
│ └──────────────────────────────────┘ │
│ 关于                                 │
│ ┌──────────────────────────────────┐ │
│ │ ℹ️ 关于礼数                  >  │ │
│ └──────────────────────────────────┘ │
└────────────────────────────────────┘
```

##### AppearanceSettingsView.swift — 外观风格

**对应 Stitch 屏幕**: `bb8a4df0833a482e81044e785d2322ec`

- 3 个选项: ☀️ 浅色模式 / 🌙 深色模式 / 📱 跟随系统
- 用 Checkmark 标记当前选中项
- 使用 `@AppStorage("colorScheme")` 持久化

##### SecuritySettingsView.swift — 隐私设置

**对应 Stitch 屏幕**: `d3eb3c947cb141dd9080718c4984afc4`

- 🔐 FaceID/TouchID 解锁 — Toggle
- 📸 防截屏保护 — Toggle (标注 Pro)
- ⏱ 自动锁定时间 — Picker (立即/1分钟/5分钟/30分钟)

##### NotificationSettingsView.swift — 通知管理

**对应 Stitch 屏幕**: `ab0ebbbed8674359a9f5d159117aa9c4`

- 各类通知 Toggle: 事件提醒/还礼提醒/生日提醒
- 使用 `@AppStorage` 持久化开关状态

##### DataManagementView.swift — 导入与导出

**对应 Stitch 屏幕**: `1b5a257a3c6c42c987cc8e768f617d6c`

- 导出选项 (占位): Excel / PDF
- 导入选项 (占位): 从 Excel 导入
- Phase 1 仅 UI 占位，功能 P1 实现

##### AboutView.swift — 关于礼数

**对应 Stitch 屏幕**: `2fecdfd8ec184d60bef28012f1b90cbd`

- 应用图标 + 版本号
- 去评分
- 用户协议
- 隐私政策
- 开源许可

##### 弹窗组件

- **删除所有数据确认**: 输入 "删除所有数据" 文字确认 → 执行删除 (对应 `228a73d6a872466b9c182982a5af7840`)
- **清除缓存弹窗**: 显示缓存大小 + 确认/取消按钮 (对应 `b283289fc6004523a9462af8a7eb43d5`)

---

#### 9. 可复用组件 (Components/)

| 组件 | 文件名 | 用途 |
|------|--------|------|
| StatCard | `StatCard.swift` | 统计卡片 (icon + title + value)，用于首页摘要、联系人详情 4 宫格、统计页 |
| RecordRow | `RecordRow.swift` | 记录列表行 (emoji + 姓名 + 事件 + 金额 + 状态 + 日期) |
| ContactRow | `ContactRow.swift` | 联系人列表行 (emoji + 姓名 + 关系标签 + 净额) |
| StatusBadge | `StatusBadge.swift` | 状态标签 (🔴待还礼/🟡已收礼/🟢已完成) |
| EmptyStateView | `EmptyStateView.swift` | 空状态 (icon + message + 可选 action button) |
| ErrorStateView | `ErrorStateView.swift` | 错误状态 (message + retry button) |
| CapsuleSegmentedControl | `CapsuleSegmentedControl.swift` | 胶囊形分段器 (全部/随礼/收礼 等场景) |
| RelationTagPicker | `RelationTagPicker.swift` | 关系标签选择器 (大类→子类两级) |
| EventTypePicker | `EventTypePicker.swift` | 事件类型网格选择器 (3x2 emoji 图标) |
| EmojiAvatarPicker | `EmojiAvatarPicker.swift` | Emoji 头像选择器 |
| LoadingState | `LoadingState.swift` | 通用异步状态枚举 (idle/loading/loaded/error) |
| MonthlyCard | `MonthlyCard.swift` | 月度统计卡片 (用于统计页横向滚动) |

---

### Team 分工

| Agent | 角色 | 职责 | 隔离方式 |
|-------|------|------|---------|
| **architect** | 架构师 (team lead) | Models + Navigation + App 骨架 + Components + LoadingState + Enums | 主分支 |
| **home-records** | 首页+记录+事件开发 | HomeView/VM + RecordListView/AddRecordView/RecordDetailView/VM + EventListView/AddEventView | worktree |
| **contacts** | 联系人开发 | ContactListView/ContactDetailView/AddContactView/VM + 关系标签体系 | worktree |
| **settings-stats** | 设置+统计开发 | SettingsView 全部子页 + StatisticsView/NetValueRankingView/VM | worktree |

### 开发顺序约束

```
Phase A (architect 先行, 约 30 分钟):
  → Models/ — Contact, Record, Event, Family + 所有 enum
  → Navigation/ — AppRouter, MainTabView (5 Tab 骨架)
  → App/ — LiShuApp.swift (ModelContainer 注入)
  → Components/ — 所有可复用组件
  → Utilities/ — LoadingState.swift
  → 编译验证: xcodebuild 必须通过
  → 完成后通知其他 agent 开始

Phase B (并行开发):
  → home-records: 首页 + 记录模块 + 事件模块
     依赖: Models/, Components/, Navigation/
     文件: Views/Home/*, Views/Records/*, Views/Events/*,
           ViewModels/HomeViewModel.swift, ViewModels/RecordListViewModel.swift

  → contacts: 联系人模块
     依赖: Models/, Components/, Navigation/
     文件: Views/Contacts/*,
           ViewModels/ContactListViewModel.swift

  → settings-stats: 设置 + 统计模块
     依赖: Models/, Components/, Navigation/
     文件: Views/Settings/*, Views/Statistics/*,
           ViewModels/StatisticsViewModel.swift

Phase C (集成):
  → architect 合并所有 worktree 分支
  → 解决合并冲突
  → 全量 xcodebuild 编译验证
  → 检查 Tab 导航和路由连通性
```

### 强制约束 (所有 Agent 必须遵守)

1. **读 CLAUDE.md** — 开工前必须先读 `CLAUDE.md` 和 `DesignTokens.swift`，严格遵守所有规范
2. **设计系统** — UI 只能用 `DesignSystem.Colors.*`, `DesignSystem.Typography.*`, `DesignSystem.Radius.*`
3. **组件样式** — 按钮用 `PrimaryButtonStyle()` / `SecondaryButtonStyle()` / `GhostButtonStyle()`，输入框用 `StandardTextFieldStyle()`
4. **UI 参考** — 通过 Stitch MCP `get_screen` 获取对应页面 HTML 作为 UI 实现参考 (见上方屏幕索引表)
5. **架构** — MVVM: `@Observable` ViewModel + View 只负责渲染，ViewModel 不 import SwiftUI
6. **文件组织** — 严格按 CLAUDE.md 中的目录结构放置文件
7. **编译** — 每个 agent 完成后必须运行 `xcodebuild -project LiShu.xcodeproj -scheme LiShu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` 确认编译通过
8. **中文** — 所有面向用户的文案使用中文，通过 `Localizable.xcstrings` 本地化
9. **金额显示** — 收入(+)用绿色系，支出(-)用 `DesignSystem.Colors.primary` 赤陶色
10. **空状态** — 所有列表页必须处理空数据状态，使用 `EmptyStateView`
11. **状态机** — Record 的 status 必须自动根据 returnedAmount 计算更新
