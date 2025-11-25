import SwiftUI

struct SpeechBubble: Shape {
    var isUser: Bool
    var triangleWidth: CGFloat = 12
    var triangleHeight: CGFloat = 8
    var cornerRadius: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isUser {
            // 右側三角
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
            path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY),
                        tangent2End: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
                        radius: cornerRadius)
            path.addLine(to: CGPoint(x: rect.maxX - cornerRadius - triangleWidth, y: rect.minY))
            path.addArc(tangent1End: CGPoint(x: rect.maxX - triangleWidth, y: rect.minY),
                        tangent2End: CGPoint(x: rect.maxX - triangleWidth, y: rect.minY + cornerRadius),
                        radius: cornerRadius)
            // 三角
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius + triangleHeight / 2))
            path.addLine(to: CGPoint(x: rect.maxX - triangleWidth, y: rect.minY + cornerRadius + triangleHeight))
            path.addLine(to: CGPoint(x: rect.maxX - triangleWidth, y: rect.maxY - cornerRadius))
            path.addArc(tangent1End: CGPoint(x: rect.maxX - triangleWidth, y: rect.maxY),
                        tangent2End: CGPoint(x: rect.maxX - triangleWidth - cornerRadius, y: rect.maxY),
                        radius: cornerRadius)
            path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
            path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                        tangent2End: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius),
                        radius: cornerRadius)
        } else {
            // 左側三角
            path.move(to: CGPoint(x: rect.minX + cornerRadius + triangleWidth, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
            path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
                        tangent2End: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
                        radius: cornerRadius)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
            path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                        tangent2End: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
                        radius: cornerRadius)
            path.addLine(to: CGPoint(x: rect.minX + cornerRadius + triangleWidth, y: rect.maxY))
            path.addArc(tangent1End: CGPoint(x: rect.minX + triangleWidth, y: rect.maxY),
                        tangent2End: CGPoint(x: rect.minX + triangleWidth, y: rect.maxY - cornerRadius),
                        radius: cornerRadius)
            // 三角
            path.addLine(to: CGPoint(x: rect.minX + triangleWidth, y: rect.minY + cornerRadius + triangleHeight))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius + triangleHeight / 2))
            path.addLine(to: CGPoint(x: rect.minX + triangleWidth, y: rect.minY + cornerRadius))
        }
        path.closeSubpath()
        return path
    }
}
