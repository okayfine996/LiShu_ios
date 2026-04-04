fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios ipa

```sh
[bundle exec] fastlane ios ipa
```

Archive Release 并导出 IPA（默认 app-store，可上传 TestFlight）。可选 bump:true 在打包前先递增 build

### ios upload_app_store

```sh
[bundle exec] fastlane ios upload_app_store
```

将已有 IPA + fastlane/screenshots 上传到 App Store Connect（优先使用 frameit 的 *_framed.png；无套壳时回退 raw；元数据请在网页维护）

### ios bump_build

```sh
[bundle exec] fastlane ios bump_build
```

仅递增 Xcode 工程中的 Build 号（CFBundleVersion / agvtool）；配置了 API Key 时会与当前 Marketing Version 下 TestFlight 最新 build 对齐，避免上传冲突

### ios release_store

```sh
[bundle exec] fastlane ios release_store
```

打包 IPA 并上传 IPA + 截图到 App Store Connect（一键；默认先 bump build，可用 skip_bump 关闭）

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Generate App Store screenshots via UI tests（须命令行执行，见 docs.fastlane screenshots）

### ios screenshots_html

```sh
[bundle exec] fastlane ios screenshots_html
```

仅根据 fastlane/screenshots 下已有 PNG 重写 screenshots.html（不调 snapshot；换机后也可补预览）

### ios framed_html

```sh
[bundle exec] fastlane ios framed_html
```

仅为已有 *_framed.png 生成 framed.html（套壳+文案预览）

### ios frameit

```sh
[bundle exec] fastlane ios frameit
```

对 fastlane/screenshots 套设备壳并叠加标题（需已跑过 screenshots；依赖 ImageMagick）

### ios store_screenshots

```sh
[bundle exec] fastlane ios store_screenshots
```

先 snapshot 再 frameit，生成可上架风格的带壳+文案截图（产物为 *_framed.png）

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
