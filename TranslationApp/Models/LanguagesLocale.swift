//
//  LanguagesLocale.swift
//  TranslationApp
//
//  Created by Ahmed Ragab on 10/11/2024.
//

import Foundation

enum LanguagesLocale: String, Codable,CaseIterable {
    case enUS = "en-US"
    case arAE = "ar-AE"
    case esES = "es-ES"
    case frFR = "fr-FR"
    case deDE = "de-DE"
    case itIT = "it-IT"
    case jaJP = "ja-JP"
    case koKR = "ko-KR"
    
    var localeName: String {
        switch self {
        case .enUS: return "English (US)"
        case .arAE: return "Arabic (U.A.E)"
        case .esES: return "Spanish (Spain)"
        case .frFR: return "French (France)"
        case .deDE: return "German (Germany)"
        case .itIT: return "Italian (Italy)"
        case .jaJP: return "Japanese (Japan)"
        case .koKR: return "Korean (Korea)"
        }
    }
}
