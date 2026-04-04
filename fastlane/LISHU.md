# LiShu fastlane 说明

## 打包 IPA

```bash
fastlane ios ipa
```

产物：`fastlane/build/LiShu.ipa`（默认 `app-store` 导出）。

```bash
EXPORT_METHOD=ad-hoc fastlane ios ipa
```

打包前若要**顺带把 Build 号 +1**（与下面 `bump_build` 规则相同）：

```bash
fastlane ios ipa bump:true
```

## Build 版本号（自动递增）

- **Marketing 版本**（用户看到的 `1.1.0`）：在 Xcode → Target **LiShu** → **General** → **Version** 里改，或改工程里的 `MARKETING_VERSION`，**不会**被 fastlane 自动改。
- **Build 号**（`CURRENT_PROJECT_VERSION` / 每次上传须递增）：用 fastlane 递增，避免与 TestFlight/App Store 已存在构建冲突。

**单独只改 Build、不打包：**

```bash
fastlane ios bump_build
```

**规则：**

1. 若已配置完整的 **App Store Connect API Key**（与下文「上传」相同）：读取当前 **Version** 对应在 TestFlight 上的**最新 build**，再与**本地当前 build**取较大值 **+1**，写回工程（与远端对齐，适合 CI/多人）。
2. 若未配置 Key：仅 **本地 build +1**（上传时若远端已更高可能报冲突，需改 Key 或手动调大 build）。

**发布一键** `fastlane ios release_store` **默认会先执行 bump**；若本次不打算改号（例如重传同一构建调试）：

```bash
fastlane ios release_store skip_bump:true
```

依赖：工程已启用 **Current Project Version**（本仓库已使用 `agvtool` 可读版本，与 Xcode 中 Version/Build 一致）。

## 自动截图（snapshot）

官方流程说明：<https://docs.fastlane.tools/getting-started/ios/screenshots/>（须 **`setupSnapshot(app)` 后再 `app.launch()`**；**用命令行**跑 snapshot，仅在 Xcode 里跑测试不会生成正确截图目录）。

```bash
fastlane ios screenshots
```

**不要**单独执行裸的 `fastlane snapshot`：它会读取 `Snapfile` 并跑 UITest；若未在 `Snapfile` 中限制测试目标，会跑完整 `LiShuUITests`（与 `Fastfile` 的 `only_testing` 行为不一致）。日常出商店图请始终用上面的 **`fastlane ios screenshots`** lane；若已在本仓库 `Snapfile` 中配置 `only_testing`（与 lane 一致），再单独跑 `fastlane snapshot` 也可只跑截图用例。

`AppStoreScreenshotTests` 已按上述文档实现独立 `setUp`（不再继承 `BaseUITestCase`，避免与 `configureApplicationBeforeLaunch` 钩子混淆）。

若提示 `SnapshotHelper.swift` 过期：文件末尾须保留与当前 fastlane 一致的 `// SnapshotHelperVersion [x.xx]`（与 gem 内 `snapshot/lib/assets/SnapshotHelper.swift` 一致），或已在 `Fastfile` 中开启 `skip_helper_version_check`。本地修改了 `SnapshotHelper` 的，不要擅自改版本号。

项目内 `SnapshotHelper` 已用 `DispatchQueue.main.sync` 在主线程执行 `setupSnapshot`/`snapshot`（`setUpWithError` 可能不在主线程，勿用 `MainActor.assumeIsolated`，否则用例会极快失败）。


输出：`fastlane/screenshots/`（设备与语言见 `Snapfile`；当前为 **iPhone 17 Pro Max**、**iOS 26.1**、**zh-Hans**）。

页面顺序与 `snapshot("名称")` 在 `LiShuUITests/AppStoreScreenshotTests.swift` 中修改。

## frameit 套壳 + 文案（上架用）

依赖 ImageMagick：

```bash
brew install imagemagick
```

**首次**执行会下载全套设备框到 `~/.fastlane/frameit/`（约两百余个文件）。若出现 `SSL_connect` / 下载中断，换稳定网络后**重复执行**同一命令即可续传缓存。

| 文件 | 作用 |
|------|------|
| `screenshots/Framefile.json` | 背景、边距、字体、`stack_title`、框颜色等（须含 `"data": []`） |
| `screenshots/zh-Hans/title.strings` | **主标题**（键需出现在截图路径中，通常与 `snapshot("…")` 名称一致） |
| `screenshots/zh-Hans/keyword.strings` | **副标题/关键词**（与 `title` 成对；`Framefile.json` 中已开 `stack_title`） |
| `screenshots/assets/background.png` | 背景图（仓库已提供浅色渐变，可替换） |

产物：与原始截图同目录生成 **`原名_framed.png`**（不覆盖原始 PNG）。预览页：`fastlane/screenshots/framed.html`（在 `frameit` / `store_screenshots` 成功后自动生成；也可单独 `fastlane ios framed_html`）。

```bash
# 已有 snapshot 的 zh-Hans/*.png 后，只套壳+叠字
fastlane ios frameit

# 先 snapshot 再 frameit（一条龙）
fastlane ios store_screenshots
```

改营销文案：编辑 `title.strings` / `keyword.strings`。增删截图时同步修改 `AppStoreScreenshotTests` 里 `snapshot("…")` 与各 `.strings` 的键。

参考：[frameit](https://docs.fastlane.tools/actions/frameit/)。

## 上传 IPA + 截图到 App Store Connect（deliver）

依赖：Xcode 已登录有效签名；App Store Connect 中已创建 App，且**当前要发布的版本号**与 Xcode 里 **Marketing Version** 一致（或先在网页建好该版本）。

**推荐**：使用 [App Store Connect API Key](https://docs.fastlane.tools/app-store-connect-api/)（适合本机/CI，免交互）。任选其一：

- **JSON 文件**：在 Apple 开发者后台创建 Key，下载 `.p8` 后设置：
  - `APP_STORE_CONNECT_API_KEY_ID`
  - `APP_STORE_CONNECT_ISSUER_ID`
  - `APP_STORE_CONNECT_API_KEY_PATH` = `.p8` 的绝对或相对 `fastlane/` 的路径  
  或
- **环境变量内容**：`APP_STORE_CONNECT_API_KEY_CONTENT`（可选 `APP_STORE_CONNECT_API_KEY_IS_BASE64=1`）

未配置上述变量时，fastlane 会尝试用 **Apple ID** 登录（需已接受协议、有权限）。

### 仅上传（已有 `fastlane/build/LiShu.ipa` 与 `fastlane/screenshots/*/…png`）

```bash
fastlane ios upload_app_store
```

上传前会在 `fastlane/screenshots_deliver/` 生成待传截图：**优先使用**各语言目录下的 `*_framed.png`（frameit 套壳+标题），复制为同名无 `_framed` 后缀的文件；若某张图尚未套壳，则用对应的 raw snapshot 补齐。文案/描述等**元数据**默认不在 fastlane 里维护（`skip_metadata: true`），请在 App Store Connect 网页编辑。

### 一键：先打包再上传

```bash
fastlane ios release_store
```

若已打好包、只想上传：

```bash
fastlane ios release_store skip_ipa:true
```

若已手动调好 build 号、**不要**在发布时自动 bump：

```bash
fastlane ios release_store skip_bump:true
```

### 截图从哪来

1. `fastlane ios screenshots` 生成 raw 图（各语言目录下的 `.png`）。
2. `fastlane ios frameit` 或 `fastlane ios store_screenshots` 生成 **`*_framed.png`**（上架推荐与商店展示一致）。
3. 再执行 `upload_app_store` / `release_store`：Deliver 会尽量上传套壳图；未跑 frameit 时仍会回退为仅 raw。

参考：[upload_to_app_store](https://docs.fastlane.tools/actions/upload_to_app_store/)。
