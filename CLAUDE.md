# LiShu (礼数) - 项目规范

## 项目概述
LiShu 是一款人情往来记账 iOS 应用（iPhone），使用 SwiftUI + SwiftData 构建。
设计规范来源于 Stitch 项目 `4174518520668530705` 的 Design Specification Sheet。

## 设计系统 (Design System) - 强制约束

**所有 UI 代码必须使用 `DesignSystem` 命名空间下的设计令牌 (Design Tokens)。**
**禁止在视图代码中硬编码颜色值、字体大小、间距数值。**

设计系统文件: `LiShu/DesignSystem/DesignTokens.swift`

### 颜色规范 (自动适配 Light/Dark Mode)

| 用途 | Light Mode | Dark Mode | Token |
|------|-----------|-----------|-------|
| 主色调(赤陶色) | #B76E5A | #B76E5A | `DesignSystem.Colors.primary` |
| 金色强调 | #C5A065 | #C5A065 | `DesignSystem.Colors.accentGold` |
| 页面背景 | #F5EFE6 | #1C1B19 | `DesignSystem.Colors.bgPage` |
| 卡片背景 | #E8DDD1 | #262422 | `DesignSystem.Colors.bgCard` |
| 输入框背景 | #ECE3D7 | #2E2B29 | `DesignSystem.Colors.bgInput` |
| 标签背景 | #D9CFC4 | #363330 | `DesignSystem.Colors.bgTag` |
| 表面白色 | #FFFFFF | #2A2220 | `DesignSystem.Colors.bgSurface` |
| 图标浅底 | #F5F0EB | #2E2B29 | `DesignSystem.Colors.bgIconSubtle` |
| Pro渐变起 | #FFFCF5 | #2A2220 | `DesignSystem.Colors.proGradientStart` |
| Pro渐变止 | #FFF7E6 | #3A2E25 | `DesignSystem.Colors.proGradientEnd` |
| 边框 | #D9CFC4 | #3D3935 | `DesignSystem.Colors.border` |
| 分割线 | #D9CFC4 | #3D3935 | `DesignSystem.Colors.separator` |
| 主要文字 | #2C2C2C | #E6E1DC | `DesignSystem.Colors.textPrimary` |
| 次要文字 | #7A746E | #ABA59F | `DesignSystem.Colors.textSecondary` |
| 辅助文字 | #ABA59F | #7A746E | `DesignSystem.Colors.textTertiary` |

所有颜色通过 `Color(hexLight:hexDark:)` 自动适配 Light/Dark Mode，无需手动判断 colorScheme。

### 字体规范

| 样式 | 大小 | 字重 | 用途 | Token |
|------|------|------|------|-------|
| Title 1 | 28pt | Bold | 页面主标题 | `DesignSystem.Typography.title1` |
| Title 2 | 22pt | Bold | 二级标题 | `DesignSystem.Typography.title2` |
| Title 3 | 20pt | Semibold | 段落/区域标题 | `DesignSystem.Typography.title3` |
| Body | 16pt | Regular | 正文内容 | `DesignSystem.Typography.body` |
| Caption | 14pt | Medium | 辅助说明文字 | `DesignSystem.Typography.caption` |
| Small | 11pt | Medium | 元信息/时间戳 | `DesignSystem.Typography.small` |

### 圆角规范

| 名称 | 数值 | 用途 | Token |
|------|------|------|-------|
| card | 20pt | 卡片 | `DesignSystem.Radius.card` |
| smallCard | 14pt | 列表项/小卡片 | `DesignSystem.Radius.smallCard` |
| input | 12pt | 输入框 | `DesignSystem.Radius.input` |
| button | .infinity | 胶囊形按钮 | `DesignSystem.Radius.button` |

### 组件样式

- **主按钮**: `.buttonStyle(PrimaryButtonStyle())` — 胶囊形, 赤陶色背景, 白色文字, 按压缩放动画, 阴影
- **次按钮**: `.buttonStyle(SecondaryButtonStyle())` — 胶囊形, 赤陶色文字, 边框描边
- **幽灵按钮**: `.buttonStyle(GhostButtonStyle())` — 无背景, 次要文字色
- **输入框**: `.textFieldStyle(StandardTextFieldStyle())` — 12pt 圆角, 边框描边, bgInput 背景

### 阴影规范

- **主按钮阴影**: Light: primary 20% opacity, Dark: black 30% opacity, radius=8, y=4

## 编码规则

1. **颜色**: 只能使用 `DesignSystem.Colors.*`，禁止 `Color.red`, `Color("xxx")`, `Color(hex:)` 等硬编码
2. **字体**: 只能使用 `DesignSystem.Typography.*`，禁止 `.font(.system(size: 16))` 等硬编码
3. **圆角**: 只能使用 `DesignSystem.Radius.*`，禁止 `.cornerRadius(20)` 等硬编码
4. **按钮样式**: 统一使用 `PrimaryButtonStyle()` / `SecondaryButtonStyle()` / `GhostButtonStyle()`
5. **输入框样式**: 统一使用 `StandardTextFieldStyle()`
6. **暗色模式**: 所有颜色已内置 Light/Dark 自适应，无需手动判断 `colorScheme` 来选颜色
7. **Hex 扩展**: `Color(hexLight:hexDark:)` 和 `UIColor(hex:)` 已定义，仅限 DesignTokens.swift 内部使用
8. **字符串本地化**: 所有用户可见的字符串禁止硬编码在代码中，必须配置在 `Localizable.xcstrings` 本地化资源文件中，通过 `String(localized:)` 按 key 访问。Key 命名规则：简短、有意义、易区分，采用 `模块.场景.语义` 的点分格式 (如 `contact.list.empty`, `record.add.title`, `common.cancel`)

```swift
// 正确
Text(String(localized: "contact.list.title"))
Button(String(localized: "common.save")) { ... }
EmptyStateView(icon: "doc.text", message: String(localized: "record.list.empty"))

// 错误 — 禁止硬编码
Text("联系人")
Button("保存") { ... }
```

9. **工程质量**: 根目录配置 SwiftLint（`.swiftlint.yml`）、SwiftFormat（`.swiftformat`）。Xcode 编译时运行 SwiftLint（Run Script）。提交前建议安装 [pre-commit](https://pre-commit.com/) 并执行 `pre-commit install`（若因 `core.hooksPath` 冲突无法安装，可先 `git config --unset-all core.hooksPath` 再试，或改用团队统一的 hook 目录），以便在 `git commit` 时对**暂存** Swift 文件运行 SwiftFormat 与 `swiftlint lint --strict`。CI 在 GitHub Actions 上执行相同检查与 `xcodebuild` 编译。

10. **Preview**: 所有 View 文件必须包含 `#Preview`，确保每个视图可独立预览。需要 SwiftData 环境的 Preview 使用 `ModelContainer(for:inMemory:)` 注入示例数据

```swift
// 页面级 View
#Preview {
    ContactListView()
        .modelContainer(for: Contact.self, inMemory: true)
}

// 纯组件
#Preview {
    StatCard(title: "总支出", value: "¥12,000", icon: "arrow.up")
}
```

日期可选值避免 `!` 时，可使用 `Date?.unwrappedOrNow`（见 `LiShu/Utilities/Date+OptionalUnwrap.swift`）。

## SwiftUI 开发规范

### 1. 架构模式 — MVVM

```
View (SwiftUI) → ViewModel (@Observable) → Model / Repository → SwiftData
```

- **View**: 只负责 UI 渲染和用户交互绑定，不包含业务逻辑
- **ViewModel**: `@Observable class`，持有状态和业务逻辑，命名为 `XxxViewModel`
- **Model**: SwiftData `@Model` 类，纯数据定义，不包含 UI 逻辑
- **Repository** (可选): 封装复杂查询/聚合逻辑，ViewModel 通过 Repository 访问数据

规则:
- View 中禁止直接操作 `modelContext` 做复杂查询，简单 CRUD 可在 ViewModel 中直接调用
- ViewModel 用 `@Observable` (非 ObservableObject)，View 用 `@State` 持有
- ViewModel 不 import SwiftUI，只 import Foundation / SwiftData

```swift
// 正确
@Observable
class ContactDetailViewModel {
    var contact: Contact?
    var isLoading = false

    func load(id: PersistentIdentifier, context: ModelContext) { ... }
}

struct ContactDetailView: View {
    @State private var viewModel = ContactDetailViewModel()
    // ...
}
```

### 2. 文件组织 & 命名

```
LiShu/
├── App/                    # App 入口、配置
│   └── LiShuApp.swift
├── DesignSystem/           # 设计令牌（已有）
│   └── DesignTokens.swift
├── Models/                 # SwiftData @Model 定义
│   └── Contact.swift
├── ViewModels/             # @Observable ViewModel
│   └── ContactListViewModel.swift
├── Views/                  # 按功能模块分子目录
│   ├── Contacts/
│   │   ├── ContactListView.swift
│   │   └── ContactDetailView.swift
│   ├── Events/
│   ├── Records/
│   ├── Statistics/
│   └── Settings/
├── Components/             # 可复用 UI 组件
│   ├── CardView.swift
│   └── EmptyStateView.swift
├── Navigation/             # 路由定义
│   └── AppRouter.swift
└── Utilities/              # 工具扩展
    └── DateFormatters.swift
```

命名规则:
- **View**: `XxxView.swift` (如 `ContactListView.swift`)
- **ViewModel**: `XxxViewModel.swift` (如 `ContactListViewModel.swift`)
- **Model**: 实体名 (如 `Contact.swift`, `Record.swift`)
- **Component**: 组件名 (如 `CardView.swift`, `AvatarView.swift`)
- **struct/class**: UpperCamelCase，**变量/函数**: lowerCamelCase
- **Bool 变量**: 用 `is/has/should` 前缀 (如 `isLoading`, `hasMore`)

### 3. View 拆分 & 组件化

**拆分时机** — 满足任一即拆:
- View body 超过 **40 行**
- 逻辑块可被 **2 个以上页面复用**
- 包含独立的 **交互状态**

**拆分层次**:
```
页面 View (XxxView)         → 对应一个完整屏幕/路由
  ├── Section View           → 页面内的逻辑区块 (private struct 或 computed property)
  │   └── Component View     → 可复用组件 (放 Components/)
  └── Section View
```

规则:
- 页面内的局部子视图用 **private computed property** 或 **private struct** 提取，不单独建文件
- 跨页面复用的组件放 `Components/` 目录，用 `struct` 定义
- 组件通过参数注入数据，**禁止在组件内部直接 @Query 或访问 modelContext**
- 使用 `@ViewBuilder` 支持插槽式组件

```swift
// 页面内局部拆分 — private computed property
struct ContactListView: View {
    var body: some View {
        VStack {
            headerSection
            listSection
        }
    }

    private var headerSection: some View {
        Text("联系人")
            .font(DesignSystem.Typography.title1)
    }
}

// 跨页面复用 — Components/
struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View { ... }
}
```

### 4. 导航 & 路由

使用 **NavigationStack + enum 路由**，集中管理所有导航目的地。

```swift
// Navigation/AppRouter.swift
enum AppRoute: Hashable {
    case contactDetail(Contact)
    case eventDetail(Event)
    case addRecord(contact: Contact?)
    case settings
    // ...
}
```

规则:
- 全局使用 **一个 NavigationStack**，在 App 根视图创建
- 路由目的地用 `navigationDestination(for: AppRoute.self)` 统一注册
- 禁止在深层子视图中嵌套 `NavigationStack`
- Sheet/FullScreenCover 用 `@State var presentedSheet: SheetRoute?` 管理
- Tab 切换用 `TabView`，每个 Tab 内部有独立的 NavigationStack

```swift
// 根视图
struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .contactDetail(let contact):
                        ContactDetailView(contact: contact)
                    case .addRecord(let contact):
                        AddRecordView(contact: contact)
                    // ...
                    }
                }
        }
    }
}
```

### 5. SwiftData 数据层

**Model 定义**:
- 每个 `@Model` 类独立一个文件，放 `Models/`
- 关系用 `@Relationship` 显式声明，设置好 `deleteRule`
- 禁止在 Model 中放 UI 逻辑或 computed property 依赖 SwiftUI

```swift
@Model
final class Contact {
    var name: String
    var phone: String
    @Attribute(.externalStorage)
    var avatar: Data?
    @Relationship(deleteRule: .cascade, inverse: \Record.contact)
    var records: [Record] = []
    var createdAt: Date

    init(name: String, phone: String = "", avatar: Data? = nil) {
        self.name = name
        self.phone = phone
        self.avatar = avatar
        self.createdAt = .now
    }
}
```

**查询规则**:
- 简单列表查询用 `@Query` (在 View 中直接使用)
- 复杂查询/聚合/跨实体逻辑放到 ViewModel 中，通过 `ModelContext` 手动查询
- `ModelContainer` 在 App 入口创建并通过 `.modelContainer()` 注入

### 6. 错误处理 & Loading 状态

统一使用 **LoadingState enum** 管理异步状态:

```swift
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(String)
}
```

规则:
- 每个涉及异步操作的 ViewModel 属性用 `LoadingState` 包裹
- View 层根据 state 切换 UI: loading → ProgressView, error → 错误提示, loaded → 内容
- 空数据用 `EmptyStateView` 组件统一展示，包含图标 + 文案 + 可选操作按钮
- 用户操作错误 (如表单校验) 用 `.alert()` 展示
- 禁止 `try!` / `fatalError` 处理可恢复错误

```swift
// ViewModel
@Observable
class RecordListViewModel {
    var state: LoadingState<[Record]> = .idle

    func loadRecords(context: ModelContext) {
        state = .loading
        do {
            let records = try context.fetch(FetchDescriptor<Record>())
            state = .loaded(records)
        } catch {
            state = .error("加载失败: \(error.localizedDescription)")
        }
    }
}

// View
struct RecordListView: View {
    @State private var viewModel = RecordListViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .loaded(let records) where records.isEmpty:
                EmptyStateView(icon: "doc.text", message: "暂无记录")
            case .loaded(let records):
                List(records) { record in ... }
            case .error(let message):
                ErrorStateView(message: message, retryAction: { ... })
            }
        }
    }
}
```

## 技术栈

- Swift + SwiftUI
- SwiftData (数据持久化)
- 最低支持 iOS 18+ (Xcode 26)
- Xcode 项目 (PBXFileSystemSynchronizedRootGroup, 自动同步文件)
- Bundle ID: com.finefine.LiShu

## Stitch 设计源

- Project ID: `4174518520668530705`
- Design Theme: Light mode, customColor #b7705c, Plus Jakarta Sans, ROUND_TWELVE, saturation 2
- Device: Mobile (390×884 base)
