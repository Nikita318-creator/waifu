import UIKit
import SnapKit

// MARK: - GiftVC
class GiftVC: UIViewController {

    // MARK: - UI Components

    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let balanceView = UIView()
    private let coinIcon = UIImageView()
    private let balanceLabel = UILabel()
    private let collectionView: UICollectionView

    // MARK: - Properties
    private var userBalance: Int = CoinsService.shared.getCoins()

    // Mock data for the gift items
    private let giftItems: [GiftItem] = [
        GiftItem(imageName: "giftsIcon1", price: 5),
        GiftItem(imageName: "giftsIcon2", price: 6),
        GiftItem(imageName: "giftsIcon3", price: 7),
        GiftItem(imageName: "giftsIcon4", price: 8),
        GiftItem(imageName: "giftsIcon5", price: 9),
        
        GiftItem(imageName: "giftsIcon6", price: 10),
        GiftItem(imageName: "giftsIcon7", price: 15),
        GiftItem(imageName: "giftsIcon8", price: 20),
        GiftItem(imageName: "giftsIcon9", price: 25),
        GiftItem(imageName: "giftsIcon10", price: 30),
        
        GiftItem(imageName: "giftsIcon11", price: 50),
        GiftItem(imageName: "giftsIcon12", price: 75),
        GiftItem(imageName: "giftsIcon13", price: 100),
        GiftItem(imageName: "giftsIcon14", price: 200),
        GiftItem(imageName: "giftsIcon15", price: 500),
    ]

    var sendGiftHandler: ((GiftItem) -> Void)?
    
    // MARK: - Initializers

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        updateBalanceLabel()
        
        AnalyticService.shared.logEvent(name: "GiftVC shown", properties: ["":""])
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Title and Subtitle
        titleLabel.text = "gift.title".localize()
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        view.addSubview(titleLabel)

        // Balance View (top right)
        balanceView.backgroundColor = .secondarySystemBackground
        balanceView.layer.cornerRadius = 15
        view.addSubview(balanceView)
        balanceView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openCoins)))
        
        coinIcon.image = UIImage(systemName: "circle.fill") // Placeholder for a coin icon
        coinIcon.tintColor = .systemYellow
        balanceView.addSubview(coinIcon)

        balanceLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        balanceLabel.textColor = .label
        balanceLabel.textAlignment = .center
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.minimumScaleFactor = 0.5
        balanceView.addSubview(balanceLabel)

        // Close Button (top left)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        // Collection View
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(GiftCell.self, forCellWithReuseIdentifier: GiftCell.reuseIdentifier)
        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        balanceView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.trailing.equalToSuperview().inset(20)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(balanceView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        coinIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        balanceLabel.snp.makeConstraints { make in
            make.leading.equalTo(coinIcon.snp.trailing).offset(4)
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().inset(20)
            make.width.height.equalTo(30)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }
    }

    private func updateBalanceLabel() {
        balanceLabel.text = "\(userBalance)"
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func updateCoins() {
        userBalance = CoinsService.shared.getCoins()
        updateBalanceLabel()
    }
    
    @objc func openCoins() {
        AnalyticService.shared.logEvent(name: "GiftVC openCoins", properties: ["":""])

        let coinsView = CoinsView()
        coinsView.coinsAddedHandler = { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.updateCoins()
            }
        }
        view.addSubview(coinsView)

        coinsView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UICollectionViewDataSource
extension GiftVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return giftItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GiftCell.reuseIdentifier, for: indexPath) as? GiftCell else {
            fatalError("Could not dequeue GiftCell")
        }
        let gift = giftItems[indexPath.row]
        cell.configure(with: gift)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension GiftVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.bounds.width - 40
        let cardHeight: CGFloat = width
        
        return CGSize(width: width, height: cardHeight)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let gift = giftItems[indexPath.row]
        
        AnalyticService.shared.logEvent(name: "GiftVC didSelectItemAt", properties: ["":"\(indexPath): \(gift)"])

        if userBalance >= gift.price {
            // Show custom alert to confirm gift purchase
            let alert = GiftConfirmAlert(gift: gift) { [weak self] in
                // Logic to handle gift sending
                print("Gift sent! Price: \(gift.price)")
                if CoinsService.shared.spendCoins(gift.price) {
                    CoinsService.shared.addSentGift(gift.imageName, for: MainHelper.shared.currentAssistant?.id ?? "")
                    self?.userBalance -= gift.price
                    self?.updateBalanceLabel()
                    self?.sendGiftHandler?(gift)
                    
                    AnalyticService.shared.logEvent(name: "GiftVC gift sended", properties: ["Gift sent":"Price: \(gift.price), userBalance = \(self?.userBalance ?? 0)"])
                }
            }
            alert.show(on: self)
        } else {
            // Show "Not Enough Coins" alert
            AnalyticService.shared.logEvent(name: "Enough Coins alert", properties: ["":""])

            let alert = NotEnoughCoinsAlert()
            alert.okButtonTappedHandler = { [weak self] in
                self?.openCoins()
                alert.removeFromSuperview()
            }
            alert.show(on: self)
        }
    }
}
