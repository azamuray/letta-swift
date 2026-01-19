import SwiftUI

struct ContentView: View {
    // Получаем доступ к NetworkManager и WiFiManager
    @ObservedObject var networkManager: NetworkManager
    @ObservedObject var wifiManager: WiFiManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок с информацией
            HeaderView(networkManager: networkManager, wifiManager: wifiManager)
            
            Divider()
            
            // Основное меню
            MenuActionsView(networkManager: networkManager)
            
            Divider()
            
            // Футер с информацией
            FooterView(lastUpdate: networkManager.lastUpdate)
            
            Divider()
            
            // Кнопка выхода
            QuitButton()
        }
        .frame(width: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            wifiManager.startMonitoring()
        }
        .onDisappear {
            wifiManager.stopMonitoring()
        }
    }
}

// MARK: - Header (заголовок)
struct HeaderView: View {
    @ObservedObject var networkManager: NetworkManager
    @ObservedObject var wifiManager: WiFiManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Заголовок без иконки
            Text("Letta Network Monitor")
                .font(.headline)
                .fontWeight(.bold)
            
            if networkManager.isConnected {
                VStack(alignment: .leading, spacing: 4) {
                    // IP адрес и метка в одну строку
                    HStack(spacing: 8) {
                        Text("IP адрес:")
                            .font(.body) // Единый шрифт
                            .foregroundColor(.secondary)
                        
                        Text(networkManager.currentIP)
                            .font(.body) // Единый шрифт
                            .textSelection(.enabled)
                            .id("ip-\(networkManager.currentIP)")
                    }
                    
                    if !networkManager.countryName.isEmpty {
                        Text("Страна: \(networkManager.countryName)")
                            .font(.body) // Единый шрифт
                            .foregroundColor(.blue)
                            .id("country-\(networkManager.countryName)")
                    }
                    
                    // WiFi индикатор
                    if wifiManager.isConnectedToWiFi {
                        HStack(spacing: 4) {
                            Text(Image(systemName: "wifi"))
                                .font(.body) // Единый шрифт
                                .foregroundColor(.white)
                            
                            Text("\(wifiManager.signalStrength)%")
                                .font(.body) // Единый шрифт
                                .foregroundColor(getSignalColor(wifiManager.signalStrength))
                                .fontWeight(.semibold)
                                .frame(width: 40, alignment: .leading)
                        }
                    }
                }
            } else {
                Text("Нет подключения к интернету")
                    .foregroundColor(.red)
                    .font(.body) // Единый шрифт
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // Цвет индикатора в зависимости от качества сигнала
    private func getSignalColor(_ strength: Int) -> Color {
        switch strength {
        case 70...100:
            return .green  // Отличный сигнал
        case 40..<70:
            return .orange // Средний сигнал
        default:
            return .red    // Слабый сигнал
        }
    }
}

// MARK: - Menu Actions (кнопки меню)
struct MenuActionsView: View {
    @ObservedObject var networkManager: NetworkManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Кнопка ручной проверки
            MenuButton(
                icon: "arrow.clockwise",
                title: "Проверить сейчас",
                color: .blue
            ) {
                networkManager.manualCheck()
            }
            
            // Кнопка копирования IP
            if networkManager.isConnected {
                MenuButton(
                    icon: "doc.on.doc",
                    title: "Скопировать IP",
                    color: .gray
                ) {
                    copyToClipboard(networkManager.currentIP)
                }
            }
            
            // Разделитель перед выходом
            Divider()
                .padding(.vertical, 4)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("📋 IP скопирован: \(text)")
    }
}

// MARK: - Footer (информация внизу)
struct FooterView: View {
    let lastUpdate: Date
    
    // Форматтер даты в стиле macOS (Пн, 19 янв. 12:34)
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM HH:mm" // Пример: Пн, 19 янв. 20:30
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Последняя проверка:")
                .font(.body) // Единый шрифт
                .foregroundColor(.secondary)
            
            Text(dateFormatter.string(from: lastUpdate))
                .font(.body) // Единый шрифт
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Quit Button (кнопка выхода)
struct QuitButton: View {
    var body: some View {
        Button(action: {
            NSApplication.shared.terminate(nil)
        }) {
            Label("Выйти", systemImage: "power")
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Reusable Menu Button
struct MenuButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview (для разработки)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Создаем мок-объекты для превью
        let mockNetworkManager = NetworkManager()
        let mockWiFiManager = WiFiManager()
        
        ContentView(networkManager: mockNetworkManager, wifiManager: mockWiFiManager)
    }
}
