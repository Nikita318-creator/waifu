import UIKit
import Lottie
import SnapKit

class SplashViewController: UIViewController {
    private let animationView = LottieAnimationView(name: "splash-lottie")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        view.addSubview(animationView)
        
        animationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        animationView.play()
    }
}
