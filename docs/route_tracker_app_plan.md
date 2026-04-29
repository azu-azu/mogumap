# Route Tracker App — 別アプリ案

## コンセプト

歩いた軌跡を記録して地図に残すアプリ。YAMAP の散歩版。
yorimichi が「点の記録」なら、こちらは「線の記録」。

**"A map drawn by your footsteps."**
自分の足跡で描く地図。

## yorimichi との棲み分け

| | yorimichi | Route Tracker |
|---|---|---|
| 記録単位 | 場所（点） | ルート（線） |
| 操作 | 行った後に記録 | 歩く前に開始 |
| GPS | one-shot | continuous |
| バッテリー | 軽い | 要注意 |
| Core value | 生きた場所を地図に残す | 歩いた軌跡を地図に残す |

## 主要機能

### 1. ルート記録

- 「開始」→ GPS tracking → 「終了」
- Background location tracking
- 座標 + timestamp を数秒間隔で記録
- 記録中はロック画面 / Live Activity で状態表示

### 2. ルート表示

- Map 上に polyline で描画
- 色分け（速度、高度、時間帯）
- 開始地点・終了地点にピン

### 3. ルート情報

- 距離（km）
- 所要時間
- 平均速度
- 高低差（CoreLocation の altitude）

### 4. 振り返り

- 日付順のルート一覧
- よく歩くエリアのヒートマップ（将来）
- 写真添付（途中で撮った写真を紐付け）

## 技術構成

```
SwiftUI          画面
SwiftData        ルート・座標の保存
MapKit           地図 + MapPolyline
CoreLocation     continuous GPS tracking
ActivityKit      Live Activity（記録中表示）
```

## データモデル案

```swift
@Model
final class Route {
    var id: UUID
    var title: String
    var startDate: Date
    var endDate: Date?
    var memo: String
    var distance: Double          // meters
    var duration: TimeInterval    // seconds

    @Relationship(deleteRule: .cascade)
    var points: [RoutePoint]
}

@Model
final class RoutePoint {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var timestamp: Date
    var route: Route?
}
```

## 画面構成

```
1. HomeView          記録開始ボタン + 最近のルート一覧
2. RecordingView     記録中の地図 + 経過時間 + 距離
3. RouteDetailView   記録済みルートの詳細表示
4. RouteListView     全ルートの一覧
5. MapOverviewView   全ルートを重ねて表示
```

## Info.plist 必須キー

```
NSLocationAlwaysAndWhenInUseUsageDescription
NSLocationWhenInUseUsageDescription
UIBackgroundModes: location
```

## バッテリー対策

- `desiredAccuracy`: 通常は `kCLLocationAccuracyNearestTenMeters`（10m精度で十分）
- `distanceFilter`: 10m（10m 動かないと更新しない）
- `allowsBackgroundLocationUpdates = true`
- `pausesLocationUpdatesAutomatically = true`（静止時は自動停止）

## 開発の優先順位

```
Phase 1: 最小限の記録 + 表示
  - 開始/停止
  - GPS tracking + 保存
  - Map に polyline 表示
  - ルート一覧

Phase 2: 情報の充実
  - 距離・時間・速度の計算
  - ルート詳細画面
  - メモ・タイトル編集

Phase 3: 体験向上
  - Live Activity
  - 写真添付
  - 全ルート重ね表示

Phase 4: 発展
  - ヒートマップ
  - 共有機能
  - yorimichi との連携（ルート途中の寄り道ログを紐付け）
```

## yorimichi との連携（将来）

- Route Tracker で歩いたルート上の店を yorimichi で記録
- URL scheme or App Group で座標を共有
- 同じ地図上に「点（yorimichi）」と「線（Route Tracker）」を重ねる
