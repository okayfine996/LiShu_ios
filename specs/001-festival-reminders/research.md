# Research: Traditional Festival Reminders

## Decision 1: Use a built-in lunar festival catalog plus `Calendar(identifier: .chinese)`

**Decision**: 使用内置的 7 个传统节日定义，并通过 `Calendar(identifier: .chinese)` 将农历
月日转换为当前年份或下一年份的公历日期，生成“最近一次即将到来的节日”。

**Rationale**:
- 功能范围固定，只有 7 个内置节日，没必要引入外部日历服务。
- 该方案离线可用，符合 LiShu 的本地优先原则。
- 可测试性强，适合对每个节日建立确定性的日期计算单元测试。

**Alternatives considered**:
- 远程节日 API：增加网络依赖，不符合本地优先，也引入失败模式。
- 手写公历映射表：跨年维护成本高，且更容易出错。
- 持久化节日日期到 SwiftData：数据本质是派生值，不应持久化。

## Decision 2: Do not introduce new SwiftData persistent models

**Decision**: 不新增 `SwiftData @Model`。节日定义、节日实例、提醒摘要都使用运行时值类型和
服务层派生数据。

**Rationale**:
- 当前需求不涉及用户自定义节日，也不需要跨设备编辑或同步节日配置。
- 避免 schema migration、CloudKit 兼容和导入导出格式变更。
- 节日属于稳定的系统内置目录，适合做只读领域对象。

**Alternatives considered**:
- 新增 `Festival` 持久化模型：增加迁移和同步成本，收益不足。
- 将节日实例缓存到本地文件：增加状态一致性复杂度，没有必要。

## Decision 3: Reuse existing notification preferences

**Decision**: 节日提醒沿用现有 `notificationEnabled` 与 `eventReminder` 控制项，不新增单独的
用户设置开关。实现上新增节日提醒分类，但受现有开关统一管理。

**Rationale**:
- 规格已明确“使用现有提醒偏好控制”。
- 复用已有设置页交互和重排逻辑，改动更小，用户理解成本更低。
- 便于快速上线并减少 `AppSettings` 新键值和设置页改造。

**Alternatives considered**:
- 新增 `festivalReminder` 开关：控制更细，但与规格不完全一致，且需要额外 UI 和设置迁移。
- 完全跟随总通知开关：会丢失与事件提醒的一致性分组语义。

## Decision 4: Add a dedicated festival section to home, not a mixed “upcoming” feed

**Decision**: 首页新增独立的传统节日卡片区块，放在现有年度汇总和“即将到来的事件”之间，
不与现有 `upcomingEvents` 混排。

**Rationale**:
- 节日是系统内置的文化提醒，事件是用户自己创建的数据，概念不同。
- 混排会让排序规则和卡片样式更复杂，也会增加用户理解成本。
- 独立区块便于后续扩展为“节日提醒”能力，而不污染已有事件列表。

**Alternatives considered**:
- 并入 `upcomingEvents`：实现更省事，但会混淆系统节日与用户事件。
- 替换现有 `upcomingEvents` 区块：会破坏现有首页信息结构。

## Decision 5: Quick create should prefill the existing Add Event flow

**Decision**: 点击节日卡片后，复用现有 `AddEventView`，并以预填上下文传入节日名称、事件类型
和日期，而不是新增专门的节日详情页。

**Rationale**:
- 已澄清规格明确要求进入新建事件并预填字段。
- 复用已有新增事件流程，减少 UI 和状态分叉。
- 对测试最友好，重点只在“预填是否正确”而非新增页面。

**Alternatives considered**:
- 新增节日详情页后再跳转创建：路径更长，价值不足。
- 只预填部分字段：会降低快速创建的效率，不符合已确认规格。

## Decision 6: Reminder body should summarize contacts up to 3 names

**Decision**: 节日提醒文案最多展示前 3 个联系人姓名，超出部分统一显示为“等 X 人”，并保证
每个节日只发送 1 条汇总通知。

**Rationale**:
- 与澄清结论一致，适合移动通知文本长度。
- 降低通知轰炸风险，避免一节日多条消息。
- 适合建立稳定的格式化单元测试。

**Alternatives considered**:
- 展示全部联系人：通知过长且不可控。
- 不展示联系人：削弱提醒价值。
- 每个联系人单独发一条：体验噪音过高。
