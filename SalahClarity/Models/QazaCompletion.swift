//
//  QazaCompletion.swift
//  Salah Clarity
//
//  One row per "I prayed a qaza" tap. Multiple per day are allowed.
//

import Foundation
import SwiftData

@Model
final class QazaCompletion {
    var date: Date
    var record: QazaRecord?

    init(date: Date = .now, record: QazaRecord? = nil) {
        self.date = date
        self.record = record
    }
}
