# LiShu 实施计划文档

## 1. 文档目标

本文档用于在现有 `PRD.md` 基础上，补充一份更适合研发执行的实施方案，重点回答以下问题：

- 下一阶段优先做什么
- 每个版本具体交付什么
- 需要改哪些数据模型、页面、服务层
- 如何分阶段上线并验证效果

本文档默认基于当前项目现状制定：

- 已具备基础记账、退礼逻辑、多支付方式、OCR 入口、通知、订阅、iCloud、导入导出等基础能力
- 当前最需要补齐的是婚礼场景、导出能力、决策辅助能力与中长期留存能力

---

## 2. 总体策略

### 2.1 核心判断

当前阶段不建议优先投入 `Android`、`微信小程序` 或 `电商接入`，因为这几项会显著增加产品和工程复杂度，但对 iOS 单端的短期体验提升有限。

更合理的路线是先把以下高价值能力做深：

1. `男方/女方标签`
2. `传统礼簿 PDF 打印导出`
3. `智能随礼金额建议`
4. `年度人情报告`
5. `关系维护提醒`
6. `家庭合并核算`

### 2.2 版本推进顺序

建议按 4 个版本推进：

| 版本 | 周期 | 核心目标 |
|------|------|----------|
| Sprint 0 | 3-5 天 | 技术梳理、埋点、开关、迁移准备 |
| V1.1 | 2-3 周 | 补齐婚礼刚需与传统礼簿导出 |
| V1.2 | 2-3 周 | 上线智能随礼建议 MVP |
| V1.3 | 2-3 周 | 上线年度报告与关系维护提醒 |
| V2.0 | 3-4 周 | 上线家庭合并核算 |

---

## 3. 优先级重排建议

### 3.1 高优先级

- `男方/女方标签`
- `传统礼簿 PDF 打印导出`
- `App Store 评分链路修复与优化`

### 3.2 中高优先级

- `智能随礼金额建议`
- `年度人情报告`
- `关系维护提醒`

### 3.3 中优先级

- `家庭合并核算`

### 3.4 暂缓项

- `Android 版本`
- `微信小程序`
- `场景化礼品电商`
- `高净值 PRO 协作体系`

---

## 4. Sprint 0：技术准备阶段

### 4.1 目标

在不影响现有业务的前提下，为后续版本建立稳定的研发底座，减少模型迁移、统计口径变更和灰度发布风险。

### 4.2 交付内容

#### 产品与数据

- 明确每个待实现功能的免费版 / Pro 版边界
- 梳理当前统计口径，形成统一定义：
  - 收到金额
  - 送出金额
  - 已退礼金额
  - 未清金额
  - 净往来净值
- 统一婚礼场景字段定义，避免后续“事件级”和“记录级”含义冲突

#### 工程与架构

- 检查 `SwiftData` 模型变更是否可走轻量迁移
- 为新增功能增加 feature flag
- 为关键路径增加埋点事件
- 为 PDF、智能建议、年度报告预留服务层接口

#### QA 与发布

- 建立核心回归测试清单
- 准备灰度开关和回滚策略

### 4.3 建议新增配置

建议在 `AppSettings` 或配置层新增：

- `weddingSideEnabled`
- `ledgerPDFEnabled`
- `giftSuggestionEnabled`
- `annualReportEnabled`
- `relationshipReminderEnabled`

### 4.4 建议埋点

- 新建事件
- 新建记录
- 使用 OCR
- 导出 CSV
- 导出 PDF
- 查看智能建议
- 采用智能建议
- 生成年度报告
- 分享年度报告
- 点击去评分

### 4.5 验收标准

- 不修改现有业务逻辑行为
- 关键路径埋点可用
- 所有开关都可独立控制
- 明确模型迁移方案和回滚预案

---

## 5. V1.1：婚礼场景补齐 + 传统礼簿 PDF

## 5.1 版本目标

把 LiShu 从“通用人情记账工具”提升为“更懂婚礼场景的专业工具”，优先解决竞品已有但当前产品尚未补齐的关键需求。

## 5.2 功能一：男方 / 女方标签

### 5.2.1 产品目标

补齐婚礼场景中非常核心的统计维度，用于区分双方家庭来宾、收支结构与后续还礼参考。

### 5.2.2 交互方案

- 仅在婚礼相关事件中显示该字段
- 事件级支持设置默认归属：
  - `男方`
  - `女方`
  - `双方`
  - `未设置`
- 记录级允许覆盖事件默认值
- 统计页支持切换：
  - `全部`
  - `男方`
  - `女方`

### 5.2.3 数据模型建议

建议新增枚举：

- `CeremonySide.none`
- `CeremonySide.groom`
- `CeremonySide.bride`
- `CeremonySide.joint`

建议新增字段：

#### `Event`

- `ceremonySideRaw: String`

#### `Record`

- `ceremonySideRaw: String`

### 5.2.4 涉及模块

- `Models/Event.swift`
- `Models/Record.swift`
- `Views/Events/AddEventView.swift`
- `Views/Records/AddRecordView.swift`
- `ViewModels/AddEventViewModel.swift`
- `ViewModels/AddRecordViewModel.swift`
- `Views/Statistics/StatisticsView.swift`

### 5.2.5 验收标准

- 婚礼事件中可顺畅设置男方 / 女方归属
- 统计页可按男方 / 女方过滤
- 非婚礼事件不暴露该字段
- 老数据升级后不崩溃，默认值为 `未设置`

## 5.3 功能二：传统礼簿 PDF 打印导出

### 5.3.1 产品目标

把现有导出能力从“数据导出”升级为“可打印、可存档、可分享”的正式礼簿能力。

### 5.3.2 功能范围

支持两类导出模板：

1. `传统礼簿`
2. `现代报表`

其中 `传统礼簿` 支持：

- 按事件导出
- 按时间导出
- 只导出收礼
- 只导出送礼
- 显示姓名、金额、备注、时间
- 婚礼场景下显示男方 / 女方字段

### 5.3.3 技术方案

- 在现有 `ExportService` 基础上扩展 PDF 能力
- 使用 `UIGraphicsPDFRenderer` 生成 PDF
- 抽象模板渲染器，避免后续模板耦合在单文件中

建议新增：

- `Services/PDFReportRenderer.swift`
- `Views/Export/PDFExportPreviewView.swift`

### 5.3.4 页面流程

1. 用户进入导出页
2. 选择导出类型
3. 选择筛选条件
4. 生成预览
5. 分享 / 打印 / 保存

### 5.3.5 涉及模块

- `Services/ExportService.swift`
- `Services/PDFReportRenderer.swift`
- `Views/Settings/DataManagementView.swift`
- `Components/ShareSheet.swift`

### 5.3.6 验收标准

- `50 / 200 / 1000` 条记录导出结果正常
- 中文字体不乱码
- 分页逻辑稳定，不截断关键字段
- 200 条记录导出耗时控制在 `3 秒内`

## 5.4 功能三：评分链路优化

### 5.4.1 目标

解决当前计划中提到的“评分跳转 Bug”，并把评分行为绑定在正反馈节点，提高转化率。

### 5.4.2 建议方案

- 保留设置页“去评分”入口
- 增加软触发场景：
  - 成功导出 PDF 后
  - 连续记账若干次后
  - OCR 导入成功后
- 新用户 7 天内不打扰
- 已点击过评分的用户降低频率

### 5.4.3 验收标准

- 真机可正常跳转 App Store 评分页
- 不影响当前页面返回逻辑
- 不频繁打断主流程

---

## 6. V1.2：智能随礼金额建议 MVP

## 6.1 版本目标

上线一个可解释、离线可用、能够真正帮助用户决策的金额建议引擎，避免一开始就做成重 AI 黑盒。

## 6.2 MVP 范围

第一版只使用以下因子：

- 对方历史往来金额
- 事件类型
- 关系圈层
- 地区礼金基准
- CPI 通胀系数

第一版暂不包含：

- 大模型推理
- 联网实时抓取复杂外部数据
- 社交图谱深度推理

## 6.3 算法方案

建议公式：

```text
建议金额 = 历史基准 × 通胀系数 × 关系权重 × 地区修正 × 场景系数
```

### 6.3.1 历史基准优先级

1. 对方过去曾给我的金额
2. 同类关系 + 同类事件的历史均值
3. 地区默认礼金档位

### 6.3.2 可解释输出

建议同时输出：

- 建议区间
- 推荐值
- 理由说明
- 可调节档位：
  - `偏保守`
  - `平衡`
  - `体面`

## 6.4 技术实现

建议新增：

- `Services/GiftSuggestionService.swift`
- `Services/CPIRepository.swift`
- `Components/GiftSuggestionCard.swift`
- `ViewModels/GiftSuggestionViewModel.swift`

建议资源文件：

- `Resources/cpi_baseline.json`
- `Resources/region_baseline.json`

## 6.5 UI 接入点

- `AddRecordView`
- `EventDetailView`
- 后续可扩展到 `HomeView`

## 6.6 验收标准

- 80% 常见场景可生成建议结果
- 每次建议都能给出明确理由
- 用户可一键采用建议金额
- 离线状态下仍可正常运行

## 6.7 商业化建议

- 免费用户：每月限制若干次
- Pro 用户：无限次使用 + 更详细解释

---

## 7. V1.3：年度报告 + 关系维护提醒

## 7.1 版本目标

解决低频工具常见的“用完就走”问题，通过可回看、可分享、可提醒的能力提高留存与再次打开频率。

## 7.2 功能一：关系维护提醒

### 7.2.1 提醒逻辑

建议先做规则型提醒：

- `睡眠关系`
  - 有较高历史往来金额
  - 长时间无互动
- `待还重点关系`
  - 我欠对方金额较高
  - 且长时间未新增往来
- `节日/生日提醒`
  - 结合已有通知能力增强触达

### 7.2.2 技术方案

建议新增：

- `Services/RelationshipHealthService.swift`

在现有 `NotificationManager` 基础上新增分类：

- `relationshipMaintenance`
- `importantPendingReturn`
- `annualSummary`

### 7.2.3 UI 呈现

- 联系人详情页展示关系状态
- 统计页增加“建议维护”模块
- 设置页支持逐类通知开关

### 7.2.4 验收标准

- 不出现通知轰炸
- 每条提醒都有明确理由
- 用户可以关闭或静默某类提醒

## 7.3 功能二：年度人情报告

### 7.3.1 产品目标

将统计结果升级为真正有传播价值的年度内容资产。

### 7.3.2 建议内容结构

- 年度总收 / 总支 / 净值
- 月度趋势
- 事件类型占比
- 关系圈层占比
- 年度热力图
- 往来最频繁联系人
- 最大单笔送礼 / 收礼
- 年度总结语

### 7.3.3 输出形式

- App 内报告页
- 长图分享
- 可扩展 PDF 报告

### 7.3.4 技术方案

建议新增：

- `Services/AnnualReportService.swift`
- `Services/ShareCardRenderer.swift`
- `Views/Statistics/AnnualReportView.swift`
- `ViewModels/AnnualReportViewModel.swift`

### 7.3.5 验收标准

- 生成年报时间小于 `2 秒`
- 深浅色模式下视觉稳定
- 分享长图无错位、无遮挡、无截断

---

## 8. V2.0：家庭合并核算

## 8.1 版本目标

支持用户从“单一联系人视角”升级为“家庭核算单元视角”，满足夫妻共管、家族往来合并核算等高阶需求。

## 8.2 数据模型建议

建议新增模型：

### `HouseholdUnit`

- `name`
- `note`
- `createdAt`
- `members`

联系人侧新增关系：

- `householdUnit`

## 8.3 核心能力

- 将多个联系人归并到同一家庭单元
- 查看家庭整体净往来
- 智能建议优先参考家庭历史
- 报表和年度报告支持家庭维度

## 8.4 风险点

- 历史数据迁移复杂
- 统计口径变化较大
- 用户理解成本上升

## 8.5 发布策略

- 首版不自动合并历史数据
- 所有绑定动作均需用户确认
- 首次进入显示引导说明

## 8.6 验收标准

- 合并 / 解绑不会影响原始记录完整性
- 家庭视图与个人视图统计结果可追溯
- 不引入明显性能回退

---

## 9. 建议文件改动清单

## 9.1 重点修改

- `LiShu/Models/Event.swift`
- `LiShu/Models/Record.swift`
- `LiShu/Services/ExportService.swift`
- `LiShu/Utilities/NotificationManager.swift`
- `LiShu/ViewModels/AddEventViewModel.swift`
- `LiShu/ViewModels/AddRecordViewModel.swift`
- `LiShu/ViewModels/StatisticsViewModel.swift`

## 9.2 建议新增

- `LiShu/Services/PDFReportRenderer.swift`
- `LiShu/Services/GiftSuggestionService.swift`
- `LiShu/Services/CPIRepository.swift`
- `LiShu/Services/AnnualReportService.swift`
- `LiShu/Services/RelationshipHealthService.swift`
- `LiShu/Services/ShareCardRenderer.swift`
- `LiShu/Views/Export/PDFExportPreviewView.swift`
- `LiShu/Views/Statistics/AnnualReportView.swift`
- `LiShu/Components/GiftSuggestionCard.swift`
- `LiShu/Components/WeddingSidePicker.swift`
- `LiShu/Components/RelationshipHealthBadge.swift`

## 9.3 V2.0 再新增

- `LiShu/Models/HouseholdUnit.swift`

---

## 10. 测试计划

## 10.1 功能测试

- 男方 / 女方标签录入与统计
- PDF 导出与打印
- 智能建议生成与采用
- 年度报告生成与分享
- 家庭合并与解绑

## 10.2 回归测试

- 基础记账
- 退礼 / 部分归还 / 已清状态
- 统计总览
- OCR 导入
- CSV 导入导出
- 通知调度
- iCloud 同步

## 10.3 兼容性测试

- 系统键盘
- 搜狗输入法
- 百度输入法
- 讯飞输入法

## 10.4 性能测试

- 1000 条记录列表渲染
- 200 条记录 PDF 导出
- 年度报告生成速度
- 大量通知重排

---

## 11. 发布节奏建议

### 第一阶段

- 完成 `Sprint 0`
- 灰度上线 `男方/女方标签`
- 内测 PDF 礼簿导出

### 第二阶段

- 正式上线 `V1.1`
- 观察婚礼事件使用率、导出转化率、评分转化

### 第三阶段

- 灰度上线 `智能随礼建议`
- 观察建议查看率、采用率、订阅转化率

### 第四阶段

- 上线 `年度报告` 和 `关系维护提醒`
- 观察月活、回访率、分享率

### 第五阶段

- 在统计与建议能力稳定后再推进 `家庭合并核算`

---

## 12. 成功指标

建议为每个版本定义最小可验证目标：

### V1.1

- 婚礼事件渗透率提升
- PDF 导出使用率达到预期
- App Store 评分转化提升

### V1.2

- 智能建议查看率
- 建议采用率
- Pro 转化率提升

### V1.3

- 年报生成率
- 年报分享率
- 关系提醒点击率
- 月活和次月留存提升

### V2.0

- 家庭单元创建率
- 家庭视图访问率
- 高净值用户留存提升

---

## 13. 最终建议

如果只选一条最优路线，建议按以下顺序推进：

1. `V1.1`：男方 / 女方标签 + 传统礼簿 PDF + 评分链路修复
2. `V1.2`：智能随礼金额建议 MVP
3. `V1.3`：年度报告 + 关系维护提醒
4. `V2.0`：家庭合并核算

这条路线兼顾：

- 用户感知强
- 研发改造可控
- 与当前代码结构匹配
- 能持续提高留存与付费转化

---

## 14. 附注

本文档为执行级计划文档，不替代 `PRD.md`。后续建议再补两份配套文档：

- `TASK_BREAKDOWN.md`：研发任务拆解表
- `RELEASE_CHECKLIST.md`：版本上线清单
