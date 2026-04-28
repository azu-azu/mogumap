# Yorimichi

自分が生きた瞬間を、地図に残すアプリ。  
*"A personal map of lived moments."*

Travel / Food のライフログを Swarm + 写真 + 食べ歩きメモとして1つに統合する iOS アプリ。

## Features

- **Place Log** — 行った場所を日時・カテゴリ・メモ・写真・評価付きで記録
- **Map View** — 記録を地図上にピン表示。自分の人生が地図になる
- **Timeline** — 日付順のログ一覧
- **Search / Filter** — 店名・カテゴリ・日付・評価で検索

## Tech Stack

- SwiftUI / Swift 6.0
- SwiftData
- MapKit
- PhotosPicker
- CoreLocation
- Deployment Target: iOS 17.0

## Build

[XcodeGen](https://github.com/yonaskolb/XcodeGen) で `project.yml` からプロジェクトを生成:

```bash
xcodegen generate
open yorimichi.xcodeproj
```
