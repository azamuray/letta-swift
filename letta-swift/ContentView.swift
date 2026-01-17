import SwiftUI

struct ContentView: View {
    // Получаем доступ к NetworkManager
    @ObservedObject var networkManager: NetworkManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок с информацией
            HeaderView(networkManager: networkManager)
            
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
        .frame(width: 300)
    }
}

// MARK: - Header (заголовок)
struct HeaderView: View {
    @ObservedObject var networkManager: NetworkManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: networkManager.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(networkManager.isConnected ? .green : .red)
                    .font(.title2)
                
                Text("Letta Network Monitor")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            if networkManager.isConnected {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IP адрес:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(networkManager.currentIP)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled) // Можно копировать
                        .id("ip-\(networkManager.currentIP)") // Идентификатор для правильного обновления
                    
                    if !networkManager.countryName.isEmpty {
                        Text("Страна: \(networkManager.countryName)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .id("country-\(networkManager.countryName)") // Идентификатор для правильного обновления
                    }
                }
            } else {
                Text("Нет подключения к интернету")
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Последняя проверка:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(lastUpdate, style: .time)
                    .font(.caption)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(lastUpdate, style: .date)
                    .font(.caption)
            }
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
        // Создаем мок-объект для превью
        let mockManager = NetworkManager()
        
        ContentView(networkManager: mockManager)
    }
}
