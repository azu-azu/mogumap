import SwiftUI
import SwiftData
import UIKit

@main
struct YorimichiApp: App {
    init() {
        UICollectionView.appearance().backgroundColor = .clear
        UICollectionViewCell.appearance().backgroundColor = .clear
        UICollectionReusableView.appearance().backgroundColor = .clear
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [PlaceLog.self, PhotoAttachment.self])
    }
}
