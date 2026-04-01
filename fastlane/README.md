# App Store 截图自动化

## 1) 安装依赖

```bash
sudo gem install fastlane
```

## 2) 执行截图

在项目根目录运行：

```bash
fastlane ios screenshots
```

截图输出目录：

```text
fastlane/screenshots
```

## 3) 已配置说明

- 使用 `LiShuUITests/AppStoreScreenshotTests`
- 默认设备：`iPhone 16 Pro Max`、`iPhone 16 Pro`
- 默认语言：`zh-Hans`

## 4) 自定义文案/页面顺序

编辑 `LiShuUITests/AppStoreScreenshotTests.swift` 中的：

- `snapshot("01-首页-总览")`
- `snapshot("02-人情-记录")`
- `snapshot("03-人脉-管理")`
- `snapshot("04-事件-场景")`
- `snapshot("05-设置-个人中心")`
