# Nearby Search を Google Places API に移行する Plan

## 前提

- Map 表示は Apple MapKit のまま変えない
- nearby 検索のデータソースだけ Google Places API (New) に差し替える
- 変更範囲は ViewModel 層のみ。View 側は struct の差し替えで対応

## 必要な準備

1. Google Cloud Console でプロジェクト作成
2. Places API (New) を有効化
3. API key を発行し、iOS bundle ID (`com.yorimichi.app`) で制限をかける
4. Billing account（クレジットカード）登録
5. 月次 quota と budget alert を設定（例: 月1万リクエスト上限）

## コスト

- 月 $200 の無料クレジット（Google Maps Platform 全体）
- Nearby Search (New): $0.032/request → 月 約6,250回 無料
- 個人利用なら余裕で収まる
- 公開する場合は quota 上限の設定が必須

## 変更対象ファイル

### 1. `NearbyPlaceSearchViewModel.swift`（変更）

- `MKLocalPointsOfInterestRequest` → Google Places Nearby Search API に差し替え
- REST API を直接叩く（SDK 不要、URLSession で十分）
- endpoint: `https://places.googleapis.com/v1/places:searchNearby`
- request body:

```json
{
  "includedTypes": ["cafe", "restaurant", "store", "museum", "bakery"],
  "maxResultCount": 10,
  "locationRestriction": {
    "circle": {
      "center": { "latitude": 35.xxxx, "longitude": 139.xxxx },
      "radius": 500.0
    }
  }
}
```

- header: `X-Goog-Api-Key`, `X-Goog-FieldMask`（必要なフィールドだけ指定して課金を抑える）
- FieldMask 例: `places.displayName,places.formattedAddress,places.location,places.primaryType`

### 2. 新規 model struct（新規）

`MKMapItem` の代わりに自前の struct を定義:

```swift
struct NearbyPlace: Identifiable, Hashable {
    let id: String           // Google place ID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: Category
}
```

### 3. `NearbyPlaceSearchView.swift`（変更）

- `MKMapItem` → `NearbyPlace` に型を変更
- `PlaceRow` の表示内容はほぼそのまま

### 4. `LogListView.swift`（変更）

- `MKMapItem` → `NearbyPlace` に型を変更

### 5. `AddLogView.swift`（変更）

- `selectedPlace: MKMapItem?` → `selectedPlace: NearbyPlace?` に変更
- `applySelectedPlace` を `NearbyPlace` 用に書き換え

### 6. API key 管理

- `.gitignore` に追加: API key を含むファイル
- `Secrets.plist` or Xcode Configuration (.xcconfig) で管理
- コードに直接ハードコードしない

## テキスト検索

- Google Places Text Search API: `https://places.googleapis.com/v1/places:searchText`
- $0.032/request（Nearby Search と同額）
- `locationBias` で現在地付近を優先できる

## やらないこと

- Google Maps SDK の導入（Map 表示は Apple MapKit のまま）
- Google Places SDK の導入（REST API 直叩きで十分）

## 移行タイミングの判断基準

- Apple Maps の nearby 結果に不満が出た時
- アプリを公開して他人が使う段階になった時
- レビューや営業時間など追加情報が欲しくなった時
