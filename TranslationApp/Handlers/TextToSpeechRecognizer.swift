//
//  TextToSpeechRecognizer.swift
//  TranslationApp
//
//  Created by Ahmed Ragab on 10/11/2024.
//

import SwiftUI
import Speech
import AVFoundation

actor TextToSpeechRecognizer  {
    private let synthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    private var currentSpeechTask: Task<Void,Never>?
    private var delegate: SpeechSynthesizerDelegate?
    @MainActor var onSpeechStateChange: ((SpeechStatus) -> Void)?
    init()  {
        
        Task {
            await initDelegates()
        }
    }
    
    func initDelegates() async {
        self.delegate = SpeechSynthesizerDelegate(actor: self)
        self.synthesizer.delegate = delegate
    }
    enum SpeechStatus {
        case started
        case stopped
        case completed
        case cancelled
    }
    
    func speak(text: String, lang: LanguagesLocale) async {
        // Cancel any existing speech
        currentSpeechTask?.cancel()
        
        // Notify about speech start

        await onSpeechStateChange?(.started)
        
        
        currentSpeechTask = Task {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: lang.rawValue)
            // Configure additional utterance properties if needed

            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            utterance.volume = 1.0
            
            // Start speaking and wait until finished
            
            if !synthesizer.isSpeaking {
                await withCheckedContinuation { continuation in
                    synthesizer.speak(utterance)
                    
                    continuation.resume()
                }
            }
        }
        // Wait for the speech task to complete or get canceled

        await currentSpeechTask?.value
    }
    func stopSpeaking() {
           synthesizer.stopSpeaking(at: .immediate)
           currentSpeechTask?.cancel()
           
           // Notify about speech cancellation
        Task { await onSpeechStateChange?(.cancelled) }
       }
}


// Delegate class for handling AVSpeechSynthesizerDelegate
final class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    private let actor: TextToSpeechRecognizer

    init(actor: TextToSpeechRecognizer) {
        self.actor = actor
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Call the actor method to handle the finished speech
        Task {
            await actor.onSpeechStateChange?(.completed)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task {
            await actor.onSpeechStateChange?(.cancelled)
        }
    }
    
}

