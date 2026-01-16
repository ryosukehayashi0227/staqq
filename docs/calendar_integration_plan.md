# カレンダー連携・リマインダー機能 実装プラン

## 概要
Staqq内のドキュメント（チラシ、プリント）の情報をもとに、iOS標準カレンダーへ予定を登録する機能を実装します。これにより、ユーザーは提出期限や行事日程を普段使いのカレンダーアプリで管理し、通知を受け取ることができます。

## 技術スタック
- **EventKit**: カレンダーイベントの読み書きを行うための標準フレームワーク。
- **EventKitUI**: カレンダーイベント編集画面(`EKEventEditViewController`)を表示するためのUIフレームワーク。

## 実装ステップ

### 1. 権限設定 (Info.plist)
まず、ユーザーのカレンダーにアクセスするための許可リクエスト文言を追加します。
- `NSCalendarsUsageDescription`: 「行事予定や提出期限をカレンダーに登録するために使用します。」

### 2. データフロー
`DocumentCard` のデータを利用して、`EKEvent` オブジェクトを作成します。

| Staqqデータ | カレンダーイベント (`EKEvent`) | 備考 |
| --- | --- | --- |
| `title` | `title` | ドキュメントのタイトルをそのまま使用 |
| `eventDate` | `startDate` / `endDate` | 行事日がある場合、その日時に設定（時間はデフォルト1時間など） |
| `deadlineDate` | `startDate` / `endDate` | 提出期限がある場合、その日時または終日イベントとして設定 |
| `id` (UUID) | `url` / `notes` | `staqq://document/{id}` のようなディープリンクを含めることで、カレンダーからアプリに戻れるようにする |

### 3. UI/UXフロー
1. **トリガー**: `DocumentDetailView` の日付表示エリアの横、またはアクションメニューに「カレンダーに追加 (Add to Calendar)」ボタンを配置。
2. **権限チェック**: ボタンタップ時にカレンダーアクセス権限を確認。未許可ならリクエスト。
3. **編集シート表示**: `EKEventEditViewController` をモーダル表示。
   - タイトル、日時があらかじめ入力された状態で立ち上がる。
   - ユーザーはここで時間を微調整したり、通知（アラート）設定、カレンダーの種別（仕事/プライベート）を選択できる。
   - **メリット**: アプリ側で複雑な日時設定UIを作る必要がなく、iOS標準の使い勝手を提供できる。
4. **完了**: ユーザーが「追加」を押すとカレンダーに保存され、シートが閉じる。

### 4. ディープリンク (Deep Linking) 対応（オプション推奨）
カレンダーの予定からStaqqの該当ドキュメントをワンタップで開けるようにします。
- **URL Scheme**: `staqq://` を定義。
- **ハンドリング**: アプリ起動時にURLを受け取り、該当する `DocumentCard.id` を検索して詳細画面に遷移させるロジックを追加。

## コード設計案

### CalendarManager (Service)
```swift
import EventKit
import EventKitUI

class CalendarManager: ObservableObject {
    let store = EKEventStore()
    
    // 権限リクエスト
    func requestAccess() async -> Bool { ... }
    
    // イベント作成用ヘルパー
    func createEvent(from document: DocumentCard) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = document.title
        // 日付設定ロジック...
        // URL設定ロジック...
        return event
    }
}
```

### ビューへの組み込み
`DocumentDetailView` に `ManageCalendarButton` を配置し、`sheet` で `EventEditViewController` (UIViewControllerRepresentable) を表示する。

## 懸念点・注意点
- **日時がnilの場合**: `eventDate` も `deadlineDate` もないドキュメントの場合、カレンダー登録ボタンを押した時にどうするか？
  - 案: 現在時刻から1時間の予定としてとりあえず作成し、ユーザーに日時を変更してもらう。
- **重複登録**: 同じドキュメントを何度もカレンダー登録できてしまう。
  - `DocumentCard` 側に `calendarEventIdentifier` (String) を保存しておき、既に登録済みの場合は「カレンダーを表示」または「更新」にするのがベスト。

## 次のアクション
このプランで問題なければ、まずは **「Info.plistへの権限追加」** と **「カレンダー追加ボタンのUI配置」** から実装を開始します。
