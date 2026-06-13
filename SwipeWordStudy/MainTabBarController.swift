import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarStyle()
        setupTabItems()
    }

    private func setupTabBarStyle() {
        let backgroundColor = UIColor.white
        tabBar.barTintColor = backgroundColor
        tabBar.backgroundColor = backgroundColor
        tabBar.tintColor = UIFactory.primaryColor
        tabBar.unselectedItemTintColor = UIFactory.mutedTextColor
        tabBar.isTranslucent = false
        tabBar.layer.borderColor = UIColor(red: 0.86, green: 0.90, blue: 0.94, alpha: 1).cgColor
        tabBar.layer.borderWidth = 0.5

        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = backgroundColor
            appearance.shadowColor = UIColor(red: 0.86, green: 0.90, blue: 0.94, alpha: 1)
            appearance.stackedLayoutAppearance.selected.iconColor = UIFactory.primaryColor
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIFactory.primaryColor
            ]
            appearance.stackedLayoutAppearance.normal.iconColor = UIFactory.mutedTextColor
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIFactory.mutedTextColor
            ]
            tabBar.standardAppearance = appearance
        }
    }

    private func setupTabItems() {
        let items = tabBar.items ?? []
        guard items.count >= 3 else { return }

        items[0].title = "학습하기"
        items[0].image = UIImage(systemName: "rectangle.stack")
        items[0].selectedImage = UIImage(systemName: "rectangle.stack.fill")

        items[1].title = "단어장"
        items[1].image = UIImage(systemName: "book")
        items[1].selectedImage = UIImage(systemName: "book.fill")

        items[2].title = "설정"
        items[2].image = UIImage(systemName: "gearshape")
        items[2].selectedImage = UIImage(systemName: "gearshape.fill")
    }
}
