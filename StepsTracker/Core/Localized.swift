// Localized.swift
import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localizedFormat(_ args: CVarArg...) -> String {
        String(format: self.localized, arguments: args)
    }
}
