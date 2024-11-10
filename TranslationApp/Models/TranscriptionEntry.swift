//
//  TranscriptionEntry.swift
//  TranslationApp
//
//  Created by Ahmed Ragab on 10/11/2024.
//

import Foundation

struct TranscriptionEntry: Identifiable,Equatable{
    let id = UUID()
    let text: String
    let language: LanguagesLocale
}
