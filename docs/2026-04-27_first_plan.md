Travel/Food Life Logアプリ
Swarm＋写真＋食べ歩きメモを1つに統合する。

## 最小構成 MVP

### 1. Place Log

行った場所を記録する。

項目：

```text
date
time
place_name
category
latitude
longitude
address
memo
photos
rating
```

カテゴリ例：

```text
cafe
restaurant
travel
walk
event
shop
temple
museum
other
```

## 2. Map View

地図上にピンを立てる。

見るもの：

```text
行った店
旅行先
散歩ルート
よく行く場所
```

このアプリのcore valueは **「自分の人生が地図になる」**

## 3. Timeline View

日付順で見る。

例：

```text
2026/04/27
- 新高円寺 → 二子玉川
- カフェ ○○
- ラーメン △△
```

## 4. Photo Attached Log

写真を1〜複数枚つける。

食べ歩きならこれが重要：

```text
写真
店名
食べたもの
一言メモ
また行きたいか
```

## 5. Search / Filter

最低限これ。

```text
店名検索
カテゴリ検索
日付検索
星評価検索
```

---

## アプリ名候補

よりみちログ
Yorimichi


---

## 技術構成

```text
SwiftUI
SwiftData
MapKit
PhotosPicker
CoreLocation
```

役割：

```text
SwiftUI      画面
SwiftData    記録保存
MapKit       地図
PhotosPicker 写真追加
CoreLocation 現在地取得
```

---

## 最初に作る画面

```text
1. LogListView      記録一覧
2. AddLogView       記録追加
3. MapView          地図表示
4. LogDetailView    詳細表示
5. SearchView       検索
```


---

## データモデル案

```swift
@Model
final class PlaceLog {
    var date: Date
    var placeName: String
    var category: String
    var latitude: Double?
    var longitude: Double?
    var address: String?
    var memo: String
    var rating: Int
    var isFavorite: Bool

    init(
        date: Date = Date(),
        placeName: String,
        category: String = "other",
        latitude: Double? = nil,
        longitude: Double? = nil,
        address: String? = nil,
        memo: String = "",
        rating: Int = 0,
        isFavorite: Bool = false
    ) {
        self.date = date
        self.placeName = placeName
        self.category = category
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.memo = memo
        self.rating = rating
        self.isFavorite = isFavorite
    }
}
```

---

**“A personal map of lived moments.”**
自分が生きた瞬間を、地図に残すアプリ。
