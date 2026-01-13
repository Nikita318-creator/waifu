import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let firstLaunchKey = "isFirstLaunch"

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        initServices()
        
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        window.rootViewController = SplashViewController()
        window.makeKeyAndVisible()
        self.window = window
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.checkFlowAndShow()
        }
    }

    private func checkFlowAndShow() {
        let isNotFirstLaunch = UserDefaults.standard.bool(forKey: firstLaunchKey)
        
        if isNotFirstLaunch {
            showMainInterface()
        } else {
            showOnboarding()
        }
    }

    private func showOnboarding() {
        let onboardingVC = OnboardingViewController()
        
        onboardingVC.onFinish = { [weak self] in
            UserDefaults.standard.set(true, forKey: self?.firstLaunchKey ?? "")
            self?.showMainInterface()
        }
        
        setRootViewController(onboardingVC)
    }

    private func showMainInterface() {
        let tabBar = createTabBar()
        setRootViewController(tabBar)
    }

    private func setRootViewController(_ vc: UIViewController) {
        guard let window = self.window else { return }
        
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
            window.rootViewController = vc
        }, completion: nil)
    }

    private func initServices() {
        let _ = NetworkMonitor.shared
        let _ = MainHelper.shared
        let _ = IAPService.shared
        let _ = RemoteRealmPhotoService.shared
        let _ = RemotePhotoService.shared
        let _ = AvatarsService.shared
        let _ = RemoteVideoService.shared
    }
    
    private func createTabBar() -> UITabBarController {
        let tabBarController = UITabBarController()
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0)]
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)]

        tabBarController.tabBar.standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = tabBarAppearance
        }
        
        let rootVC = AllChatsViewController()
        let roleplayVC = RoleplayVC()
        let gamesViewController = GamesViewController()
        
        let rootNavController = UINavigationController(rootViewController: rootVC)
        let roleplayNavController = UINavigationController(rootViewController: roleplayVC)
        let gamesGFNavController = UINavigationController(rootViewController: gamesViewController)
        
        roleplayNavController.setNavigationBarHidden(true, animated: false)
        
        tabBarController.delegate = self
        
        rootNavController.tabBarItem = UITabBarItem(
            title: "Messages".localize(),
            image: UIImage(systemName: "message"),
            tag: 0
        )
        
        roleplayNavController.tabBarItem = UITabBarItem(
            title: "Roleplay".localize(),
            image: UIImage(systemName: "sparkles"),
            tag: 1
        )
        
        gamesGFNavController.tabBarItem = UITabBarItem(
            title: "Games".localize(),
            image: UIImage(systemName: "gamecontroller"),
            tag: 2
        )
        
        tabBarController.viewControllers = [rootNavController, roleplayNavController, gamesGFNavController]
        tabBarController.selectedIndex = 1
        return tabBarController
    }
    
    private func handleDeepLink(url: URL) {
        AnalyticService.shared.logEvent(name: "handleDeepLink: \(url)", properties: ["":""])
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

extension SceneDelegate: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
         if let nav = tabBarController.selectedViewController as? UINavigationController,
            let selectedNav = viewController as? UINavigationController,
            nav == selectedNav,
            nav.viewControllers.count > 1 {
             return false
         }
         
         return true
     }
}
