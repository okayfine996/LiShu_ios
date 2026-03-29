# Data Model: Traditional Festival Reminders

## Overview

本功能不新增 `SwiftData` 持久化模型。所有节日相关数据均为运行时派生值，通过内置节日目录、
联系人筛选结果和事件预填上下文组成。

## Entity: TraditionalFestivalDefinition

**Purpose**: 描述一个内置传统节日的静态定义。

**Fields**:
- `id`: 稳定标识，用于排序、测试和通知去重
- `nameKey`: 本地化 key，对应节日名称
- `lunarMonth`: 农历月份
- `lunarDay`: 农历日期
- `eventType`: 对应的事件类型，当前统一映射到 `EventType.festival`
- `sortPriority`: 同日节日的稳定排序字段

**Validation Rules**:
- `id` 必须唯一
- `lunarMonth` 范围为 `1...12`
- `lunarDay` 范围为 `1...30`
- 内置目录仅允许 7 条固定记录

## Entity: TraditionalFestivalOccurrence

**Purpose**: 表示某个节日在某次最近未来发生时的具体实例，用于首页展示和通知调度。

**Fields**:
- `festivalID`: 对应 `TraditionalFestivalDefinition.id`
- `name`: 已本地化的展示名称
- `date`: 该节日下一次发生的公历日期
- `daysRemaining`: 距离当前日期的剩余天数
- `eventType`: 快速创建事件时使用的事件类型

**Validation Rules**:
- `date` 必须是当前日期之后的下一次有效发生日
- `daysRemaining` 必须大于等于 0
- 同一个 `festivalID` 同一时刻只能存在一个“当前下一次发生”的实例

## Entity: FestivalReminderPayload

**Purpose**: 汇总某个节日提醒通知需要展示的文案信息。

**Fields**:
- `festivalID`: 节日标识
- `festivalName`: 节日展示名
- `occurrenceDate`: 节日发生日
- `reminderDate`: 发送通知的日期，固定为节日前 1 天
- `contactNames`: 命中的联系人姓名列表
- `displayNames`: 最多 3 个用于展示的联系人姓名
- `remainingCount`: 超出展示名额的人数
- `bodyText`: 最终通知正文

**Validation Rules**:
- 每个节日实例只生成一条提醒 payload
- `displayNames.count <= 3`
- `remainingCount >= 0`
- 当 `contactNames` 为空时，`bodyText` 仍须是完整可读文案

## Entity: CloseContactGroup

**Purpose**: 用于节日提醒筛选的联系人子集。

**Source**:
- 现有 `Contact.category`
- 现有 `Contact.circle`

**Selection Rule**:
- 当前版本仅包含“家人”和“亲属”分类联系人

**Validation Rules**:
- 去重后按稳定顺序输出
- 缺失姓名的联系人不得进入提醒文案

## Entity: FestivalEventPrefill

**Purpose**: 点击节日卡片后传给现有新建事件流程的预填上下文。

**Fields**:
- `name`: 节日名称
- `eventType`: `EventType.festival`
- `date`: 节日发生日期

**Validation Rules**:
- 预填值必须能直接映射到现有 `AddEventViewModel`
- 用户进入新建事件页后仍可编辑全部字段

## Existing Models Touched

### `Contact`

**Used for**:
- 提取“家人/亲属”联系人
- 生成节日提醒联系人名单

**No schema change planned**

### `Event`

**Used for**:
- 快速创建节日事件
- 保持事件类型为现有 `EventType.festival`

**No schema change planned**

## State Transitions

### Festival card lifecycle

1. 应用加载首页
2. 读取内置节日目录
3. 计算每个节日的下一次发生日期
4. 选出最近 3 个节日实例
5. 输出给首页卡片区块展示

### Reminder lifecycle

1. 用户开启现有通知总开关与事件提醒开关
2. 应用重排全部通知
3. 为每个节日实例生成最多 1 条提醒 payload
4. 筛选家人/亲属联系人并生成提醒文案
5. 调度本地通知

### Quick create lifecycle

1. 用户点击首页节日卡片
2. 生成 `FestivalEventPrefill`
3. 打开现有新建事件流程
4. 预填节日名称、事件类型和日期
5. 用户确认或编辑后保存为普通 `Event`

## Migration & Compatibility

- 无 SwiftData schema migration
- 无 CloudKit 模型变更
- 无导入导出格式变更
- 需要补充本地化资源 key
- 需要扩展现有通知调度逻辑，但不改变现有事件/生日/回礼提醒的数据结构
