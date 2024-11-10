//
//  SpeechRecognitionViewModel.swift
//  TranslationApp
//
//  Created by Ahmed Ragab on 10/11/2024.
//

import SwiftUI


@Observable
class SpeechRecognitionViewModel {
     var transcript: String = ""
     var transcriptions: [TranscriptionEntry] = []
     var selectedLanguage: LanguagesLocale = .enUS {
        didSet {
            Task {
               await recognizer.configureRecognizer(locale: selectedLanguage)
            }
        }
    }
    
    // New UI state properties
     var isReading: Bool = false
     var isReadingComplete: Bool = false
     var isReadingError: Bool = false
    
     var currentReadingIndex: Int?  // Track the current item being read

    
    private let recognizer = SpeechRecognizer()
    private let textToSpeechActor = TextToSpeechRecognizer() // Initialize the text-to-speech actor
    
    init() {
        // Listen for speech status changes
        Task { @MainActor in
            textToSpeechActor.onSpeechStateChange = { [weak self] status in
                Task {
                     self?.handleSpeechStatusChanged(status)
                }
            }
        }
    }
    
    func observeTranscription() {
        Task {
            for await newTranscript in await recognizer.$transcription.values {
                self.transcript = newTranscript
            }
        }
    }
    
    func startRecording() async {
        do {
            try await recognizer.startTranscription()
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
            self.transcript = "Error: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() async {
        do {
            try await recognizer.stopTranscribing()
            addTranscription()
        } catch {
            print("Failed to stop recording: \(error.localizedDescription)")
        }
    }
    
    private func addTranscription() {
        // Add the transcription to the list with animation
        withAnimation {
            let entry = TranscriptionEntry(text: transcript, language: selectedLanguage)
            transcriptions.insert(entry, at: 0)
            transcript = "" // Reset the temporary transcript
        }
    }
    
    func readTranscription(_ entry: TranscriptionEntry) async {
        isReading = true
        isReadingComplete = false
        isReadingError = false
        
        await textToSpeechActor.speak(text: entry.text, lang: entry.language)
    }
    
    func stopReading() async {
        await textToSpeechActor.stopSpeaking()
        isReading = false
        isReadingComplete = false
        isReadingError = false
    }
    
    // Handle speech status updates
    private func handleSpeechStatusChanged(_ status: TextToSpeechRecognizer.SpeechStatus) {
        switch status {
        case .started:
            isReading = true
            isReadingComplete = false
            isReadingError = false
        case .completed:
            isReading = false
            isReadingComplete = true
            isReadingError = false
        case .cancelled:
            isReading = false
            isReadingComplete = false
            isReadingError = true
        case .stopped:
            Task {
               await stopReading()
            }
        }
    }
}
