//
//  SpeechRecognizer.swift
//  TranslationApp
//
//  Created by Ahmed Ragab on 10/11/2024.
//

import Speech
import SwiftUI

actor SpeechRecognizer {
    @MainActor  @Published var transcription: String = ""
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init(lang: LanguagesLocale = .enUS) {
        Task {
           await configureRecognizer(locale: lang)
        }
    }
    
    func configureRecognizer(locale: LanguagesLocale) {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale.rawValue))
    }
    
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func requestMicrophoneAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func startTranscription() async throws {
        guard await requestAuthorization(), await requestMicrophoneAccess() else {
            throw NSError(domain: "SpeechRecognition", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permissions not granted"])
        }
        
        guard let speechRecognizer = self.speechRecognizer, speechRecognizer.isAvailable else {
            throw NSError(domain: "SpeechRecognition", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is not available."])
        }
        
        self.request = SFSpeechAudioBufferRecognitionRequest()
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start the recognition task
        self.recognitionTask = speechRecognizer.recognitionTask(with: request!) { [weak self] result, error in
            if let result = result {
                Task { @MainActor in
                    self?.transcription = result.bestTranscription.formattedString
                }
            }
            if let error = error {
                print("Recognition error: \(error.localizedDescription)")
            }
        }
    }
    
    func stopTranscribing() async throws {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        request?.endAudio()
    }
}
