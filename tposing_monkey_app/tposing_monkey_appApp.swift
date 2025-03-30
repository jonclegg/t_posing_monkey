//
//  tposing_monkey_appApp.swift
//  tposing_monkey_app
//
//  Created by Jonathan Clegg on 3/29/25.
//

import SwiftUI
import AVFoundation

// ================================================================================
class AudioPlayer {
    static let shared = AudioPlayer()
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    func startBackgroundMusic() {
        // Configure the audio session
        configureAudioSession()
        
        guard let url = Bundle.main.url(forResource: "background_music", withExtension: "m4a") else {
            print("Error: Background music file 'background_music.m4a' not found in bundle.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 0.5 // Set initial volume (adjust as needed)
            audioPlayer?.prepareToPlay() // Prepare the player
            audioPlayer?.play()
            print("Background music started successfully.")
        } catch {
            print("Error: Failed to initialize or play background music: \(error.localizedDescription)")
        }
    }
    
    func stopBackgroundMusic() {
        audioPlayer?.stop()
        print("Background music stopped.")
    }
    
    func setVolume(_ volume: Float) {
        // Ensure volume is between 0.0 and 1.0
        let clampedVolume = max(0.0, min(1.0, volume))
        audioPlayer?.volume = clampedVolume
        print("Background music volume set to: \(clampedVolume)")
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback allows audio to play even when the screen is locked or the Ring/Silent switch is set to silent.
            // .mixWithOthers allows other app audio to play concurrently (optional, remove if you want exclusive audio)
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            print("Audio session configured successfully.")
        } catch {
            print("Error: Failed to configure audio session: \(error.localizedDescription)")
        }
    }
}
// ================================================================================

@main
struct tposing_monkey_appApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    
    init() {
        // Set preferred orientations to landscape only
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
    }

    var body: some Scene {
        WindowGroup {
            StartView()
        }
    }
}
// ================================================================================

// App Delegate for controlling orientation and starting music
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.landscape
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Start playing background music when app launches
        AudioPlayer.shared.startBackgroundMusic()
        return true
    }
}
