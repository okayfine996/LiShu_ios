# LiShu fastlane 说明

## 打包 IPA

```bash
fastlane ios ipa
```

产物：`fastlane/build/LiShu.ipa`（默认 `app-store` 导出）。

```bash
EXPORT_METHOD=ad-hoc fastlane ios ipa
```

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
