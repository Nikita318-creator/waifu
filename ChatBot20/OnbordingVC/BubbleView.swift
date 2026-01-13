import UIKit

class BubbleView: UIView {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let bubbleColor = UIColor(white: 1.0, alpha: 0.1)
        let cornerRadius: CGFloat = 20
        let tailWidth: CGFloat = 20
        let tailHeight: CGFloat = 12
        
        let path = UIBezierPath()
        
        // Начинаем с левого верхнего угла
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        
        // Верхняя сторона
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: cornerRadius),
                         controlPoint: CGPoint(x: rect.width, y: 0))
        
        // Правая сторона
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - tailHeight - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.width - cornerRadius, y: rect.height - tailHeight),
                         controlPoint: CGPoint(x: rect.width, y: rect.height - tailHeight))
        
        // Нижняя сторона до хвостика
        let tailStartX = rect.width / 2 - tailWidth / 2
        path.addLine(to: CGPoint(x: tailStartX + tailWidth, y: rect.height - tailHeight))
        
        // Хвостик (плавная кривая как в Telegram)
        path.addCurve(to: CGPoint(x: tailStartX, y: rect.height - tailHeight),
                     controlPoint1: CGPoint(x: tailStartX + tailWidth * 0.8, y: rect.height - tailHeight * 0.3),
                     controlPoint2: CGPoint(x: tailStartX + tailWidth * 0.2, y: rect.height))
        
        // Продолжаем нижнюю сторону
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height - tailHeight))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.height - tailHeight - cornerRadius),
                         controlPoint: CGPoint(x: 0, y: rect.height - tailHeight))
        
        // Левая сторона
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(to: CGPoint(x: cornerRadius, y: 0),
                         controlPoint: CGPoint(x: 0, y: 0))
        
        path.close()
        
        // Заливаем фон
        bubbleColor.setFill()
        path.fill()
        
        // Добавляем тень для красоты
        if let shadowPath = path.copy() as? UIBezierPath {
            shadowPath.apply(CGAffineTransform(translationX: 0, y: 1))
        }
        
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.setShadow(offset: CGSize(width: 0, height: 2), blur: 8, color: UIColor.black.withAlphaComponent(0.1).cgColor)
        bubbleColor.setFill()
        path.fill()
        context?.restoreGState()
    }
}
