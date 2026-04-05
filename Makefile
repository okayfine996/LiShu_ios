# LiShu — 本地格式化 / Lint（需 Homebrew：swiftformat、swiftlint）
.PHONY: format lint format-lint

format:
	swiftformat LiShu LiShuTests LiShuUITests --config .swiftformat

lint:
	swiftlint lint --strict

format-lint: format lint
