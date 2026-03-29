# UI Contract: Traditional Festival Reminders

## 1. Home Festival Cards

### Purpose

在首页提供固定的传统节日卡片区块，用于展示最近 3 个即将到来的传统节日。

### Inputs

- `festivalOccurrences`: 已按时间升序排列的 `TraditionalFestivalOccurrence` 列表
- `maxDisplayCount`: 固定值 3

### Rendering Rules

- 只渲染最近 3 个节日
- 每张卡片显示：
  - 节日名称
  - 剩余天数
  - 节日日期
- 卡片顺序必须与输入顺序一致
- 卡片点击区域为整卡

### Empty State

- 如果节日数据生成失败，首页必须退化为不显示该区块或显示安全空态
- 不得影响现有首页其他区块渲染

## 2. Festival Reminder Notification

### Purpose

为每个节日实例生成一条汇总通知，提醒用户问候亲密联系人。

### Inputs

- `festivalName`
- `occurrenceDate`
- `matchedContactNames`

### Formatting Rules

- 每个节日实例只允许 1 条通知
- 通知正文最多显示 3 个联系人姓名
- 超出时使用“等 X 人”总结
- 无联系人时仍需生成可读正文

### Example Output

- 有联系人：
  - `中秋节即将到来，别忘了问候张三、李四、王五等 2 人`
- 无联系人：
  - `中秋节即将到来，别忘了提前安排节日问候`

## 3. Quick Create Event Entry

### Purpose

点击首页节日卡片后，直接进入现有新建事件流程并注入节日预填值。

### Input Contract

- `FestivalEventPrefill`
  - `name`
  - `eventType`
  - `date`

### Required Behavior

- 进入的是现有新建事件页，不是新页面
- 进入时必须预填：
  - 节日名称
  - 事件类型
  - 节日日期
- 用户可继续修改所有字段后保存

## 4. Settings Integration

### Purpose

确保节日提醒遵守现有通知设置。

### Rules

- 节日提醒受总通知开关控制
- 节日提醒受现有事件提醒开关控制
- 关闭提醒不会影响首页节日卡片展示

## 5. Compatibility Contract

### Must Not Break

- 现有首页“即将到来的事件”区块
- 现有事件提醒、生日提醒、回礼提醒
- 现有事件新增/编辑流程
- 现有本地化和深浅色模式行为
