import UIKit
import SnapKit

class CustomPayWallV1VC: UIViewController {
    
    override func loadView() {
        super.loadView()
        
        let customPayWallV1View = CustomPayWallV1View()
        customPayWallV1View.vc = self
        view = customPayWallV1View
    }
}
