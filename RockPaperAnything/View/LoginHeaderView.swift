//
//  LoginHeaderView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/22/25.
//

import CoreGraphics
import SwiftUI

func getCircleCorner(center: CGPoint, radius: CGFloat, radians: CGFloat) -> CGPoint {
    let x = center.x + radius * cos(radians)
    let y = center.y + radius * sin(radians)
    return CGPoint(x: x, y: y)
}
struct LoginHeaderView: View {
    @State private var imagePositions: [CGPoint] = [
        CGPoint(x: 100, y: 100),
        CGPoint(x: 300, y: 100),
        CGPoint(x: 200, y: 225)
    ]
    
    @State private var rockIndex = 0
    private let rockNames = (1...5).map {
        "rock\($0)"
    }
    
    @State private var paperIndex = 0
    private let paperNames = (1...5).map {
        "paper\($0)"
    }
    
    @State private var anythingIndex = 0
    private let anythingNames = (1...5).map {
        "anything\($0)"
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                
                CurvedText(text: "Rock", radius: 65, angleSpan: .pi / 7, position: .top)
                    .frame(width: 100, height: 20)
                    .position(imagePositions[0])
                Image(rockNames[rockIndex])
                    .resizable()
                    .clipShape(Circle())
                    .shadow(radius: 5)
                    .frame(width: 100, height: 100)
                    .position(imagePositions[0])
                    .animation(.easeInOut(duration: 1.5), value: rockIndex)
                    .task {
                        await startTimer(delay: 0, interval: 3) {
                            rockIndex = Int.random(in: 0..<rockNames.count)
                        }
                    }
                
                CurvedText(text: "Paper", radius: 65, angleSpan: .pi / 5.5, position: .top)
                    .frame(width: 100, height: 20)
                    .position(imagePositions[1])
                Image(paperNames[paperIndex])
                    .resizable()
                    .clipShape(Circle())
                    .shadow(radius: 5)
                    .frame(width: 100, height: 100)
                    .position(imagePositions[1])
                    .animation(.easeInOut(duration: 1.5), value: paperIndex)
                    .task {
                        await startTimer(delay: 1, interval: 3) {
                            paperIndex = Int.random(in: 0..<paperNames.count)
                        }
                    }
                
                CurvedText(text: "Anything", radius: 65, angleSpan: .pi / 4, position: .bottom)
                    .frame(width: 100, height: 20)
                    .position(imagePositions[2])
                Image(anythingNames[anythingIndex])
                    .resizable()
                    .clipShape(Circle())
                    .shadow(radius: 5)
                    .frame(width: 100, height: 100)
                    .position(imagePositions[2])
                    .animation(.easeInOut(duration: 2), value: anythingIndex)
                    .task {
                        await startTimer(delay: 2, interval: 3) {
                            anythingIndex = Int.random(in: 0..<anythingNames.count)
                        }
                    }
                
                Arrow(
                    from: CGPoint(x: 160, y: 100),
                    to: CGPoint(x: 240, y: 100),
                    curvature: 1.5)
                .stroke(style: StrokeStyle(
                    lineWidth: 3,
                    lineCap: .round))
                
                Arrow(
                    from: getCircleCorner(
                        center: imagePositions[1],
                        radius: 60,
                        radians: .pi / 4 * 2.7),
                    to: getCircleCorner(
                        center: imagePositions[2],
                        radius: 60,
                        radians: -.pi / 4),
                    curvature: -0.6)
                .stroke(style: StrokeStyle(
                    lineWidth: 3,
                    lineCap: .round))
                
                Arrow(
                    from: getCircleCorner(
                        center: imagePositions[2],
                        radius: 60,
                        radians: .pi / 4 * 5),
                    to: getCircleCorner(
                        center: imagePositions[0],
                        radius: 60,
                        radians: .pi / 3.2),
                    curvature: -0.6)
                .stroke(style: StrokeStyle(
                    lineWidth: 3,
                    lineCap: .round))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    func startTimer(delay: TimeInterval, interval: TimeInterval, action: @escaping () -> Void) async {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            action()
        }
    }
}

struct CurvedText: View {
    let text: String
    let radius: CGFloat
    let angleSpan: CGFloat
    let position: Position
    
    enum Position {
        case top, bottom
    }

    var body: some View {
        GeometryReader { geometry in
            let angle = angleSpan / CGFloat(text.count - 1)
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2

            ForEach(0..<text.count, id: \.self) { index in
                let char = text[text.index(text.startIndex, offsetBy: index)]
                let xOffset = radius * cos(angle * CGFloat(index) - angleSpan / 2 - .pi / 2)
                let yOffset = radius * sin(angle * CGFloat(index) - angleSpan / 2 - .pi / 2)

                Text(String(char))
                    .bold()
                    .position(x: centerX + xOffset, y: centerY + (position == .top ? yOffset : -yOffset))
                    .rotationEffect(.radians(Double(angle * CGFloat(index) - angleSpan / 2) * (position == .top ? 1 : -1)))
            }
        }
    }
}

struct Arrow: Shape {
    let from: CGPoint
    let to: CGPoint
    let curvature: CGFloat // Parameter to control the curve
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Calculate control points for the curve
        let dx = to.x - from.x
        let dy = to.y - from.y
        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
        
        // Calculate the perpendicular vector to the line
        let perpDX = -dy
        let perpDY = dx
        
        // Normalize the perpendicular vector
        let normFactor = sqrt(perpDX*perpDX + perpDY*perpDY)
        let unitPerpDX = perpDX / normFactor
        let unitPerpDY = perpDY / normFactor
        
        // Calculate the control point
        let controlPoint = CGPoint(
            x: midX + curvature * unitPerpDX * abs(dx),
            y: midY + curvature * unitPerpDY * abs(dy)
        )
        
        // Start the path at the 'from' point
        path.move(to: from)
        
        // Add a quadratic Bezier curve
        path.addQuadCurve(to: to, control: controlPoint)
        
        // Calculate the tangent at a small offset from the end point of the quadratic curve
        let t: CGFloat = 0.9
        let tangentX = 2 * (1 - t) * (controlPoint.x - from.x) + 2 * t * (to.x - controlPoint.x)
        let tangentY = 2 * (1 - t) * (controlPoint.y - from.y) + 2 * t * (to.y - controlPoint.y)
        
        let angle = atan2(tangentY, tangentX)
        
        // Add arrowhead
        let arrowLength: CGFloat = 10.0
        let arrowAngle: CGFloat = .pi / 5.0 // 30 degrees
        
        let arrowPoint1 = CGPoint(
            x: to.x - arrowLength * cos(angle - arrowAngle),
            y: to.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: to.x - arrowLength * cos(angle + arrowAngle),
            y: to.y - arrowLength * sin(angle + arrowAngle)
        )
        
        path.move(to: to)
        path.addLine(to: arrowPoint1)
        path.move(to: to)
        path.addLine(to: arrowPoint2)
        
        return path
    }
}

#Preview(
    "Objects List",
    traits: .sizeThatFitsLayout
) {
    LoginHeaderView()
}
