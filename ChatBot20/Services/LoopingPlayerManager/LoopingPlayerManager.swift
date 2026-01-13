import AVFoundation
import UIKit

class LoopingAudioManager: NSObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?

    override init() {
        super.init()
        configureAudioSession() // Важный фикс
        setupRandomAudioPlayer()
    }

    private func configureAudioSession() {
        do {
            // Позволяет играть аудио вместе с видео и не глохнуть от переключателя Silent
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("ERROR: Failed to set audio session category: \(error)")
        }
    }

    private func setupRandomAudioPlayer() {
        let randomIndex = Int.random(in: 1...8)
        let audioFileName = "audio\(randomIndex)"
        
        guard let url = Bundle.main.url(forResource: audioFileName, withExtension: "m4a") else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0.4 // Сделал чуть громче, раз видео будет молчать
            audioPlayer?.prepareToPlay()
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
    }
    
    func play() { audioPlayer?.play() }
    func pause() { audioPlayer?.pause() }
}

class LoopingPlayerManager: NSObject {
    let player: AVPlayer
    private let audioManager: LoopingAudioManager
    
    private var rateObserver: NSKeyValueObservation?
    private var videoLoopToken: NSObjectProtocol?
    
    init(player: AVPlayer, audioManager: LoopingAudioManager) {
        self.player = player
        self.audioManager = audioManager
        super.init()
        
        self.player.isMuted = true
        setupLooping()
        setupRateObservation()
    }
    
    private func setupLooping() {
        if let token = videoLoopToken {
            NotificationCenter.default.removeObserver(token)
        }

        guard let playerItem = player.currentItem else { return }
        
        videoLoopToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main) { [weak self] _ in
                self?.player.seek(to: .zero)
                self?.player.play()
            }
    }
    
    private func setupRateObservation() {
        rateObserver = player.observe(\.rate, options: [.new]) { [weak self] player, change in
            guard let self = self else { return }
            if player.rate > 0 {
                self.audioManager.play()
            } else {
                self.audioManager.pause()
            }
        }
    }

    deinit {
        if let token = videoLoopToken {
            NotificationCenter.default.removeObserver(token)
        }
        
        audioManager.pause()
    }
}
