import UIKit
import SnapKit

// MARK: - CoinsView
class CoinsView: UIView {

    // MARK: - UI Components
    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let collectionView: UICollectionView
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    var coinsAddedHandler: (() -> Void)?
    
    // MARK: - Properties
    private var packages: [CoinPackage] = [
        CoinPackage(id: CoinsIDs.coins10, amount: 10, price: "", imageName: "coins_10"),
        CoinPackage(id: CoinsIDs.coins20, amount: 20, price: "", imageName: "coins_20"),
        CoinPackage(id: CoinsIDs.coins50, amount: 50, price: "", imageName: "coins_50"),
        CoinPackage(id: CoinsIDs.coins100, amount: 100, price: "", imageName: "coins_100"),
        CoinPackage(id: CoinsIDs.coins500, amount: 500, price: "", imageName: "coins_500"),
        CoinPackage(id: CoinsIDs.coins1000, amount: 1000, price: "", imageName: "coins_1000")
    ]
    
    let isWardrobe: Bool
    
    // MARK: - Initializers
    init(isWardrobe: Bool = false) {
        self.isWardrobe = isWardrobe
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(frame: .zero)
        
        getCoinPrices()
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func getCoinPrices() {
        let prices = CoinsService.shared.allLocalizedPrices()
        for (id, price) in prices {
            if let index = packages.firstIndex(where: { $0.id == id }) {
                packages[index].price = price
            }
        }
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        backgroundColor = .systemBackground

        // Close Button
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        addSubview(closeButton)
        
        // Title and Subtitle
        titleLabel.text = isWardrobe ? "Wardrobe.Coins.Title".localize() : "Coins.Title".localize()
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)

        subtitleLabel.text = isWardrobe ? "Wardrobe.Coins.SubTitle".localize() : "Coins.SubTitle".localize()
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        addSubview(subtitleLabel)
        
        // Collection View
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CoinsPackageCell.self, forCellWithReuseIdentifier: CoinsPackageCell.reuseIdentifier)
        addSubview(collectionView)
        addSubview(loadingIndicator)
    }

    private func setupConstraints() {
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        if isWardrobe {
            closeButton.snp.makeConstraints { make in
                make.top.trailing.equalTo(safeAreaLayoutGuide)
                make.width.height.equalTo(30)
            }
            
            titleLabel.snp.makeConstraints { make in
                make.top.trailing.equalTo(safeAreaLayoutGuide)
                make.leading.trailing.equalToSuperview().inset(20)
            }
        } else {
            closeButton.snp.makeConstraints { make in
                make.top.trailing.equalToSuperview().inset(16)
                make.width.height.equalTo(30)
            }
            
            titleLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(50)
                make.leading.trailing.equalToSuperview().inset(20)
            }
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
    }

    // MARK: - Actions
    @objc private func closeButtonTapped() {
        self.removeFromSuperview()
    }
    
    func showLoadingIndicator() {
        loadingIndicator.startAnimating()
        isUserInteractionEnabled = false
        superview?.isUserInteractionEnabled = false
    }
    
    func hideLoadingIndicator() {
        loadingIndicator.stopAnimating()
        isUserInteractionEnabled = true
        superview?.isUserInteractionEnabled = true
    }
}

// MARK: - UICollectionViewDataSource
extension CoinsView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return packages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CoinsPackageCell.reuseIdentifier, for: indexPath) as? CoinsPackageCell else {
            fatalError("Could not dequeue CoinsPackageCell")
        }
        let package = packages[indexPath.row]
        cell.loadingIAPHandler = { [weak self] isStarted in
            if isStarted {
                self?.showLoadingIndicator()
            } else {
                self?.hideLoadingIndicator()
                self?.removeFromSuperview()
                self?.coinsAddedHandler?()
            }
        }
        cell.configure(with: package)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CoinsView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 16) / 2
        let height = width * 1.1
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? CoinsPackageCell
        cell?.priceButtonTapped()
    }
}
