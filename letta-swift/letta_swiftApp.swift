import SwiftUI

@main
struct letta_swiftApp: App {
    // Создаем менеджеры, которые будут жить всё время работы приложения
    @StateObject private var networkManager = NetworkManager()
    @StateObject private var wifiManager = WiFiManager()
    
    var body: some Scene {
        // MenuBarExtra создает приложение в меню-баре
        // Используем эмодзи флагов вместо системных иконок
        MenuBarExtra(content: {
            // Передаем менеджеры в ContentView
            ContentView(networkManager: networkManager, wifiManager: wifiManager)
        }, label: {
            Text(networkManager.iconName)
                .font(.system(size: 14))
        })
        .menuBarExtraStyle(.window)
    }
}
