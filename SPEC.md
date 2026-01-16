# Staqq アプリケーション仕様書

## 概要
Staqqは、学校のプリントやチラシをスキャンし、整理・管理するためのiOSアプリケーションです。OCRによる自動タイトル・日付解析、カレンダー連携、期限管理機能を備え、散らかりがちな紙の書類をデジタル化して一元管理します。

## 技術スタック
- **言語**: Swift 6
- **UIフレームワーク**: SwiftUI
- **データ永続化**: SwiftData
- **画像認識/OCR**: Vision Framework, VisionKit
- **描画機能**: PencilKit
- **カレンダー連携**: EventKit, EventKitUI
- **PDF生成**: PDFKit

## データモデル

### DocumentCard (主要モデル)
書類1件を表すデータモデル。`@Model` マクロによりSwiftDataで管理されます。

| プロパティ名 | 型 | 属性 | 説明 |
| :--- | :--- | :--- | :--- |
| `id` | UUID | `@Attribute(.unique)` | 一意の識別子 |
| `imageData` | `[Data]` | `@Attribute(.externalStorage)` | スキャン画像データの配列（複数ページ対応） |
| `drawingData` | `[Data]` | `@Attribute(.externalStorage)` | 画像上の書き込みデータ（PencilKit） |
| `title` | `String` | | ドキュメントのタイトル（OCRで自動推定可能） |
| `eventDate` | `Date?` | | 行事開催日などの日付 |
| `deadlineDate` | `Date?` | | 提出期限などの締め切り日 |
| `childTag` | `String` | | フォルダ分け用のタグ（子供の名前など） |
| `notes` | `String` | | OCRで認識された全文テキスト、またはユーザーメモ |
| `isArchived` | `Bool` | | アーカイブ状態（完了した書類） |
| `createdAt` | `Date` | | 作成日時 |

### AppTag
タグ管理用のモデル。
| プロパティ名 | 型 | 説明 |
| :--- | :--- | :--- |
| `name` | `String` | タグ名 |
| `colorHex` | `String` | カラーコード |

## 機能詳細

### 1. ドキュメントスキャン機能
- **実装**: `ScannerView` (UIViewControllerRepresentable wrapping `VNDocumentCameraViewController`)
- **機能**:
    - カメラによる書類の自動検出と撮影
    - 自動台形補正（透視変換）
    - 複数ページの連続スキャン
- **自動解析 (OCR)**:
    - `OCRDocumentService` がスキャン完了後にバックグラウンドで実行
    - `Vision` フレームワークを使用し、画像内のテキストを認識
    - **タイトル推定**: フォントサイズが最も大きく、かつ意味のある文字列をタイトルとして提案
    - **日付検出**: `NSDataDetector` を使用して日付文字列を検出し、イベント日として提案

### 2. 書類管理・一覧 (MainView / Sidebar)
- **ナビゲーション**: サイドバーによる機能切り替え
- **カテゴリ**:
    - **Inbox**: 未アーカイブの書類を表示
    - **Upcoming Deadlines**: `deadlineDate` が3日以内の書類を表示
    - **Smart Folders**: `childTag` ごとに自動分類されたフォルダ
    - **Archived**: アーカイブ済みの全書類
- **リスト表示**:
    - `DocumentListView` にてグリッド/リスト表示
    - **パフォーマンス最適化**: `DocumentRow` にて画像の非同期読み込みとダウンサンプリングを実施 (`CGImageSource`)

### 3. 詳細閲覧・編集 (DocumentDetailView)
- **手書きメモ**: `CanvasView` (PencilKit) により、スキャン画像の上に直接手書きが可能
- **情報編集**: タイトル、タグ、日付の変更
- **カレンダー追加**: アプリ内からiOS標準カレンダーにイベントを追加 (`EventEditViewController`)
- **共有**: 画像と書き込みを合成してPDF化し、他アプリへ共有 (`ShareLink`)

### 4. 検索機能
- `.searchable` モディファイアによる全文検索
- 検索対象: タイトル (`title`) および OCR全文 (`notes`)

### 5. ヘルプ機能
- アプリの基本的な使い方を解説するヘルプ画面
- 多言語対応（英語/日本語）

## ファイル構成
- **Views**: UIコンポーネント (`MainView`, `DocumentListView`, `DocumentDetailView` など)
- **Models**: データ定義 (`DocumentCard`)
- **Services**: ロジック層 (`OCRDocumentService`, `CalendarManager`)
- **Resources**: ローカライゼーション (`Localizable.xcstrings`)
