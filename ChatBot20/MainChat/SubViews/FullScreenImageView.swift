import UIKit
import SnapKit
import Photos // Импортируем Photos для работы с галереей

class FullScreenImageView: UIView {

    // MARK: - UI Components

    private let containerView = UIView()
    private let imageView = UIImageView()

    // Свойства для масштабирования и перемещения
    private var currentScale: CGFloat = 1.0
    private var currentTranslation: CGPoint = .zero
    
    // Кнопки для взаимодействия
    private let closeButton = UIButton(type: .system)
    private let downloadButton = UIButton(type: .system) // Новая кнопка
    private let statusLabel = UILabel() // Лейбл для уведомлений о статусе

    weak var vc: UIViewController?
    
    // MARK: - Initialization

    init(image: UIImage?) {
        super.init(frame: .zero)
        setupViews()
        imageView.image = image
        
        AnalyticService.shared.logEvent(name: "FullScreenImageView opened", properties: ["":""])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        // Полупрозрачный черный фон
        backgroundColor = UIColor.black.withAlphaComponent(0.0)
        
        // Настройка ImageView
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        
        // Настройка кнопки закрытия
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        ), for: .normal)
        closeButton.tintColor = .white
        closeButton.alpha = 0.0
        closeButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        
        // Настройка кнопки скачивания
        downloadButton.setImage(UIImage(systemName: "square.and.arrow.down")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        ), for: .normal)
        downloadButton.tintColor = .white
        downloadButton.alpha = 0.0
        downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)

        // Жест тапа по фону для закрытия
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        addGestureRecognizer(tapGesture)

        // Контейнер для трансформаций
        containerView.isUserInteractionEnabled = true
        addSubview(containerView)
        containerView.addSubview(imageView)
        
        // Добавление кнопок и лейбла на основное вью
        addSubview(closeButton)
        addSubview(downloadButton)
        
        // Настройка лейбла статуса
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.alpha = 0.0
        addSubview(statusLabel)

        // Жесты
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(pinch)
        containerView.addGestureRecognizer(pan)
        
        setupConstraints()
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.lessThanOrEqualToSuperview().multipliedBy(0.8)
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(44)
        }
        
        // Констрейнты для новой кнопки "Download"
        downloadButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide).inset(16)
            make.width.height.equalTo(44)
        }
        
        // Констрейнты для лейбла статуса
        statusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(downloadButton.snp.top).offset(-16)
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .changed, .ended:
            currentScale *= gesture.scale
            currentScale = max(0.5, min(currentScale, 3.0))
            updateTransform()
            gesture.scale = 1.0
        default: break
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed, .ended:
            let translation = gesture.translation(in: containerView)
            currentTranslation.x += translation.x
            currentTranslation.y += translation.y
            updateTransform()
            gesture.setTranslation(.zero, in: containerView)
        default: break
        }
    }

    private func updateTransform() {
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: currentScale, y: currentScale)
        transform = transform.translatedBy(x: currentTranslation.x, y: currentTranslation.y)
        containerView.transform = transform
    }
    
    // MARK: - Actions
    
    @objc private func downloadButtonTapped() {
        AnalyticService.shared.logEvent(name: "FullScreenImageView downloadButtonTapped", properties: ["":""])

        guard let imageToSave = imageView.image else { return }
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            saveImage(imageToSave)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
                        self.saveImage(imageToSave)
                    } else {
                        self.showStatusMessage("galery.PermissionRejected".localize())
                    }
                }
            }
        case .denied, .restricted:
            showStatusMessage("galery.PermissionRejected".localize())
            showGaleryPermissionAlert()
        @unknown default:
            print("Unknown permission status.")
        }
    }
    
    private func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            showStatusMessage("galery.SaveError".localize())
        } else {
            showStatusMessage("galery.Saved".localize())
        }
    }
    
    private func showStatusMessage(_ message: String) {
        self.statusLabel.text = message
        UIView.animate(withDuration: 0.3, animations: {
            self.statusLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 1.0, delay: 1.5, options: [], animations: {
                self.statusLabel.alpha = 0.0
            })
        }
    }

    // MARK: - Public Methods

    func show(in parentView: UIView) {
        guard !MainHelper.shared.isImageOpened else { return }
        MainHelper.shared.isImageOpened = true
        
        parentView.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Анимация появления
        UIView.animate(withDuration: 0.3) {
            self.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            self.closeButton.alpha = 1.0
            self.downloadButton.alpha = 1.0 // Анимируем появление кнопки
        }
    }

    @objc func dismiss() {
        MainHelper.shared.isImageOpened = false

        // Анимация исчезновения
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            self.closeButton.alpha = 0.0
            self.downloadButton.alpha = 0.0 // Анимируем исчезновение кнопки
            self.statusLabel.alpha = 0.0 // Скрываем лейбл статуса при закрытии
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    private func showGaleryPermissionAlert() {
        let alert = UIAlertController(
            title: "PermissionDenied".localize(),
            message: "PermissionDenied.Message".localize(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel".localize(), style: .cancel))
        alert.addAction(UIAlertAction(title: "OpenSettings".localize(), style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
            }
        })
        vc?.present(alert, animated: true)
    }
}
