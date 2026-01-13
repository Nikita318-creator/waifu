import UIKit
import SnapKit

class DateVC: UIViewController {

    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let collectionView: UICollectionView
    private var selectedPlaceName: String?
    
    // MARK: - Properties
    private var placeItems: [DatePlaceItem] {
        if ConfigService.shared.isTestB {
            return [
                DatePlaceItem(imageName: "place1"),
                DatePlaceItem(imageName: "place2"),
                DatePlaceItem(imageName: "place3"),
                DatePlaceItem(imageName: "place4"),
                DatePlaceItem(imageName: "place5"),
                DatePlaceItem(imageName: "place6"),
                DatePlaceItem(imageName: "place7")
            ]
        } else {
            return [
                DatePlaceItem(imageName: "place1"),
                DatePlaceItem(imageName: "place3"),
                DatePlaceItem(imageName: "place4"),
                DatePlaceItem(imageName: "place6"),
                DatePlaceItem(imageName: "place7")
            ]
        }
    }

    var placeSelectedHandler: ((String, String) -> Void)?
    
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
        
        AnalyticService.shared.logEvent(name: "DateVC shown", properties: [:])
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Title
        titleLabel.text = "Date.title".localize()
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        view.addSubview(titleLabel)

        // Close Button
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        // Collection View
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(DatePlaceCell.self, forCellWithReuseIdentifier: DatePlaceCell.reuseIdentifier)
        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().inset(20)
            make.width.height.equalTo(30)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            make.leading.trailing.equalToSuperview().inset(40)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }
    }

    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func showPreferencesView(for placeName: String) {
        let prefsView = DatePreferencesView()
        self.selectedPlaceName = placeName
        
        view.addSubview(prefsView)
        prefsView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Анимация появления
        prefsView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            prefsView.alpha = 1
        } completion: { _ in
            prefsView.focusTextView()
        }
        
        prefsView.onContinue = { [weak self] instructions in
            guard let self = self, let place = self.selectedPlaceName else { return }
            self.placeSelectedHandler?(place, instructions)
            
            AnalyticService.shared.logEvent(name: "DateVC instructions added", properties: ["instructions": instructions])
        }
    }
}

// MARK: - UICollectionViewDataSource
extension DateVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return placeItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DatePlaceCell.reuseIdentifier, for: indexPath) as? DatePlaceCell else {
            return UICollectionViewCell()
        }
        let item = placeItems[indexPath.row]
        cell.configure(with: item)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension DateVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedPlace = placeItems[indexPath.row]
        AnalyticService.shared.logEvent(name: "DateVC place selected", properties: ["place": selectedPlace.imageName])
        
        showPreferencesView(for: selectedPlace.imageName)
    }
}
