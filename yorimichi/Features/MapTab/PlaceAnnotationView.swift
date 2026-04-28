import SwiftUI

struct PlaceAnnotationView: View {
    let log: PlaceLog

    var body: some View {
        let cat = Category(rawValue: log.category) ?? .other
        VStack(spacing: 0) {
            Image(systemName: cat.icon)
                .font(.caption)
                .padding(6)
                .foregroundStyle(.white)
                .background(Circle().fill(.tint))

            Image(systemName: "triangle.fill")
                .font(.system(size: 8))
                .foregroundStyle(.tint)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
    }
}
