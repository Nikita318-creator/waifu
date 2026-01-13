import AVKit
import UIKit
import MediaPlayer

final class HardcorePlayerViewController: AVPlayerViewController {
    
    private var muteObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSilentTreatment()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        eliminateVolumeControls(in: self.view)
    }
    
    private func setupSilentTreatment() {
        // 1. Подсовываем системе невидимый ползунок громкости.
        // Это перехватывает нажатия физических кнопок громкости на себя.
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.clipsToBounds = true
        volumeView.alpha = 0.001 // Почти невидимый, но рабочий
        view.addSubview(volumeView)
        
        // 2. Ставим жесткий обсервер на свойство isMuted
        guard let player = player else { return }
        
        player.isMuted = true
        
        muteObserver = player.observe(\.isMuted, options: [.new]) { [weak player] _, change in
            guard let isMuted = change.newValue else { return }
            if !isMuted {
                // Если какая-то падла (система) размьютила плеер — мьютим обратно!
                player?.isMuted = true
                print("Nice try, iOS! Video is muted again.")
            }
        }
    }
    
    private func eliminateVolumeControls(in view: UIView) {
        for subview in view.subviews {
            let className = String(describing: type(of: subview))
            
            // Удаляем кнопки из UI
            if className.contains("Volume") || className.contains("Mute") {
                subview.removeFromSuperview()
            } else {
                eliminateVolumeControls(in: subview)
            }
        }
    }
    
    deinit {
        muteObserver?.invalidate()
    }
}
