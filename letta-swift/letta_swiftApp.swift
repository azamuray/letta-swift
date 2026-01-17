import SwiftUI

@main
struct letta_swiftApp: App {
    // Создаем NetworkManager, который будет жить всё время работы приложения
    @StateObject private var networkManager = NetworkManager()
    
    var body: some Scene {
        // MenuBarExtra создает приложение в меню-баре
        // Используем эмодзи флагов вместо системных иконок
        MenuBarExtra(content: {
            // Передаем networkManager в ContentView
            ContentView(networkManager: networkManager)
        }, label: {
            Text(networkManager.iconName)
                .font(.system(size: 14))
        })
        .menuBarExtraStyle(.menu)
    }
}
