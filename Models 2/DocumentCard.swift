//
//  DocumentCard.swift
//  Staqq
//
//  Created by Hayashi Ryosuke on 2026/01/13.
//

import Foundation
import SwiftData

@Model
final class DocumentCard {
    // ユニークなID。CloudKit同期のために初期値を持たせます
    @Attribute(.unique) var id: UUID = UUID()
    
    // 複数枚の画像を保存するためのData配列
    // CloudKitの制限を考慮し、空の配列で初期化します
    var imageData: [Data] = []
    
    // AIが抽出するタイトル
    var title: String = ""
    
    // 行事日（任意）
    var eventDate: Date?
    
    // 提出期限（任意）
    var deadlineDate: Date?
    
    // 子供の名前などのタグ
    var childTag: String = ""
    
    // アーカイブフラグ（デフォルトはfalse）
    var isArchived: Bool = false
    
    // 作成日時
    var createdAt: Date = Date()

    // 初期化メソッド（イニシャライザ）
    init(
        id: UUID = UUID(),
        imageData: [Data] = [],
        title: String = "",
        eventDate: Date? = nil,
        deadlineDate: Date? = nil,
        childTag: String = "",
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.imageData = imageData
        self.title = title
        self.eventDate = eventDate
        self.deadlineDate = deadlineDate
        self.childTag = childTag
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}
