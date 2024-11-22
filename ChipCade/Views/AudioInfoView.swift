//
//  AudioInfoView.swift
//  CHIPcade
//
//  Created by Markus Moenig on 22/11/24.
//

import SwiftUI
import AVFoundation

class AVAudioPlayerDelegateHandler: NSObject, AVAudioPlayerDelegate {
    private let callback: (AVAudioPlayer, Bool) -> Void

    init(callback: @escaping (AVAudioPlayer, Bool) -> Void) {
        self.callback = callback
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        callback(player, flag)
    }
}

struct AudioInfoView: View {
    @ObservedObject var audioItem: AudioItem
    @State private var audioInfo: AudioInfo?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying: Bool = false

    @State private var delegateHandler: AVAudioPlayerDelegateHandler?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let audioInfo = audioInfo {
                Text("Audio Info")
                    .font(.headline)

                HStack {
                    Text("Name:")
                        .fontWeight(.bold)
                    Spacer()
                    Text(audioItem.name)
                }

                HStack {
                    Text("Duration:")
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(String(format: "%.2f", audioInfo.duration)) seconds")
                }

                HStack {
                    Text("Sample Rate:")
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(Int(audioInfo.sampleRate)) Hz")
                }

                HStack {
                    Text("Channels:")
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(audioInfo.channels)")
                }
            } else {
                Text("Loading audio info...")
                    .italic()
            }

            Spacer()

            Button(action: togglePlayPause) {
                Text(isPlaying ? "Pause" : "Play")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(audioInfo == nil)
        }
        .padding()
        .onAppear(perform: loadAudioInfo)
    }

    private func loadAudioInfo() {
        guard let data = audioItem.data else { return }
        do {
            // Load audio data into the player
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()

            // Create a strong reference to the delegate handler
            let handler = AVAudioPlayerDelegateHandler { [self] player, successfully in
                handlePlaybackFinished(player: player, successfully: successfully)
            }
            delegateHandler = handler
            audioPlayer?.delegate = handler
    
            // Extract audio info
            if let player = audioPlayer {
                audioInfo = AudioInfo(
                    duration: player.duration,
                    sampleRate: player.format.sampleRate,
                    channels: Int(player.format.channelCount)
                )
            }
        } catch {
            print("Failed to load audio: \(error.localizedDescription)")
        }
    }

    private func togglePlayPause() {
        guard let player = audioPlayer else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func handlePlaybackFinished(player: AVAudioPlayer, successfully: Bool) {
        if successfully {
            print("Playback finished successfully")
        } else {
            print("Playback did not finish successfully")
        }
        isPlaying = false
        audioPlayer?.currentTime = 0
    }
}

struct AudioInfo {
    let duration: TimeInterval
    let sampleRate: Double
    let channels: Int
}
