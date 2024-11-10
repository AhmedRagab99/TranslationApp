//
//  SpeechHandler.swift
//  TranslationApp
//
//  Created by Ahmed Ragab on 10/11/2024.
//

import Foundation
import Speech
import AVFoundation
import SwiftUI
import Translation

struct SpeechView: View {
    @State private var viewModel = SpeechRecognitionViewModel()
    @State private var isRecording: Bool = false
    
    @State private var showTranslation = false
    @State private var selectedText: String = ""

    
    var body: some View {
        VStack {
            Text("Speech To Text")
                .font(.largeTitle)
                .padding(.bottom, 20)
            
            // Language Picker
            Picker("Language", selection: $viewModel.selectedLanguage) {
                ForEach(LanguagesLocale.allCases, id: \.self) { language in
                    Text(language.localeName).tag(language)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            
            // Currently transcribing text
            Text(viewModel.transcript)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding()
            
            // Recording Button
            Button {
                Task {
                    if isRecording {
                        await viewModel.stopRecording()
                    } else {
                        await viewModel.startRecording()
                    }
                    isRecording.toggle()
                }
            } label: {
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .padding()
                    .foregroundColor(.white)
                    .background(isRecording ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
            
        

            // Transcriptions List with Read Button
            List {
                ForEach(viewModel.transcriptions.indices, id: \.self) { index in
                    let entry = viewModel.transcriptions[index]
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.text)
                                .font(.body)
                            Text(entry.language.localeName)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await viewModel.readTranscription(entry)
                            }
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button(action: {
                            selectedText = entry.text
                            showTranslation.toggle()
                        }) {
                            Image(systemName: "translate")
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .listStyle(PlainListStyle())
            .translationPresentation(isPresented: $showTranslation, text: selectedText)
            .onAppear {
                viewModel.observeTranscription()
            }
            .padding()
        }
    }
}
