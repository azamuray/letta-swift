import Foundation
import Network
import Combine

class NetworkManager: ObservableObject {
    // Published свойства - UI будет автоматически обновляться
    @Published var isConnected: Bool = false
    @Published var currentIP: String = "Загрузка..."
    @Published var countryCode: String = ""
    @Published var countryName: String = ""
    @Published var iconName: String = "🌐"
    @Published var lastUpdate: Date = Date()
    
    private var monitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var lastInterfaceHash: String = ""
    private var isChecking = false
    private var lastCheckTime: Date = Date.distantPast
    private let minCheckInterval: TimeInterval = 0.5 // Минимальный интервал между запросами
    private let backendURL = "http://45.130.214.133:8080"
    
    init() {
        print("🚀 NetworkManager инициализирован")
        setupNetworkMonitoring()
        performInitialCheck()
    }
    
    // Настраиваем мониторинг сети
    private func setupNetworkMonitoring() {
        monitor = NWPathMonitor()
        
        monitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            let newStatus = path.status == .satisfied
            
            DispatchQueue.main.async {
                // Обновляем статус подключения
                if self.isConnected != newStatus {
                    self.isConnected = newStatus
                    print("🔔 Сеть: \(newStatus ? "ПОДКЛЮЧЕНО" : "ОТКЛЮЧЕНО")")
                    
                    // Делаем запрос к бэкенду при подключении
                    if newStatus {
                        self.fetchBackendData()
                    } else {
                        self.updateDisconnectedState()
                    }
                }
                
                // Проверяем изменения интерфейсов (VPN, WiFi и т.д.)
                self.checkInterfaceChanges(path)
            }
        }
        
        monitor?.start(queue: monitorQueue)
    }
    
    // Проверяем изменения в интерфейсах (как в вашем Go-коде)
    private func checkInterfaceChanges(_ path: NWPath) {
        var interfaces: [String] = []
        
        if path.usesInterfaceType(.wifi) {
            interfaces.append("WiFi")
        }
        if path.usesInterfaceType(.wiredEthernet) {
            interfaces.append("Ethernet")
        }
        if path.usesInterfaceType(.cellular) {
            interfaces.append("Cellular")
        }
        if path.usesInterfaceType(.other) {
            interfaces.append("VPN/Other")
        }
        
        let newHash = interfaces.joined(separator: "|")
        
        if newHash != lastInterfaceHash && !newHash.isEmpty {
            print("🔔 Изменились интерфейсы: \(newHash)")
            lastInterfaceHash = newHash
            
            if isConnected {
                fetchBackendData()
            }
        }
    }
    
    // Первоначальная проверка при запуске
    func performInitialCheck() {
        print("📡 Первоначальная проверка сети...")
        fetchBackendData()
    }
    
    // Ручная проверка (при нажатии кнопки в меню)
    func manualCheck() {
        print("🔍 Ручная проверка...")
        fetchBackendData()
    }
    
    // Запрос к вашему Go-бэкенду
    private func fetchBackendData() {
        // Предотвращаем слишком частые запросы
        let now = Date()
        guard !isChecking else { return }
        
        // Если прошло меньше минимального интервала, откладываем запрос
        if now.timeIntervalSince(lastCheckTime) < minCheckInterval {
            let delay = minCheckInterval - now.timeIntervalSince(lastCheckTime)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.fetchBackendData()
            }
            return
        }
        
        isChecking = true
        lastCheckTime = now
        
        guard let url = URL(string: backendURL) else {
            print("❌ Неверный URL")
            isChecking = false
            return
        }
        
        print("🌍 Запрос к бэкенду: \(backendURL)")
        
        // Таймаут 2 секунды, как в Go-коде
        let request = URLRequest(url: url, timeoutInterval: 2)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isChecking = false
                self.lastUpdate = Date()
                
                if let error = error {
                    print("❌ Ошибка запроса: \(error.localizedDescription)")
                    self.handleError()
                    return
                }
                
                guard let data = data else {
                    print("⚠️ Нет данных в ответе")
                    self.handleError()
                    return
                }
                
                self.parseBackendResponse(data)
            }
        }.resume()
    }
    
    // Парсим ответ от бэкенда (как в вашем Go-коде)
    private func parseBackendResponse(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let ip = json["ip"] as? String ?? "Неизвестно"
                let countryCode = json["countryCode"] as? String ?? ""
                
                print("✅ Ответ от бэкенда:")
                print("   IP: \(ip)")
                print("   Код страны: \(countryCode)")
                
                // Обновляем UI
                self.currentIP = ip
                self.countryCode = countryCode
                self.countryName = self.getCountryName(for: countryCode)
                self.updateIcon(for: countryCode)
                self.isConnected = true
            }
        } catch {
            print("❌ Ошибка парсинга JSON: \(error)")
            self.handleError()
        }
    }
    
    // Обновляем иконку в зависимости от страны
    private func updateIcon(for countryCode: String) {
        if countryCode.isEmpty {
            iconName = isConnected ? "✅" : "❌"
        } else {
            // Генерируем эмодзи флаг для любой страны автоматически
            let flag = getFlagEmoji(for: countryCode)
            iconName = flag
        }
    }
    
    // Получаем эмодзи флаг по коду страны (ISO 3166-1 alpha-2)
    // Работает для ВСЕХ стран автоматически через региональные индикаторы Unicode
    private func getFlagEmoji(for countryCode: String) -> String {
        let code = countryCode.uppercased()
        
        // Проверяем, что код страны валидный (2 буквы)
        guard code.count == 2,
              let firstChar = code.first,
              let secondChar = code.last,
              firstChar.isLetter,
              secondChar.isLetter,
              let firstUnicode = firstChar.unicodeScalars.first,
              let secondUnicode = secondChar.unicodeScalars.first else {
            print("⚠️ Неверный код страны: \(countryCode)")
            return "🌐"
        }
        
        // Региональные индикаторы для создания флагов
        // Базовое значение для региональных индикаторов (0x1F1E6 = 127462)
        // Это стандарт Unicode для создания эмодзи флагов из двухбуквенных кодов стран
        let base: UInt32 = 127462 // 0x1F1E6
        let aValue: UInt32 = 65 // Unicode для 'A'
        
        let firstScalar = base + UInt32(firstUnicode.value - aValue)
        let secondScalar = base + UInt32(secondUnicode.value - aValue)
        
        guard let firstFlag = UnicodeScalar(firstScalar),
              let secondFlag = UnicodeScalar(secondScalar) else {
            print("⚠️ Не удалось создать флаг для кода: \(code)")
            return "🌐"
        }
        
        // Комбинируем два региональных индикатора в один эмодзи флаг
        // Это работает для ВСЕХ стран по стандарту ISO 3166-1 alpha-2
        return String(firstFlag) + String(secondFlag)
    }
    
    // Получаем название страны по коду
    private func getCountryName(for code: String) -> String {
        let countries: [String: String] = [
            "RU": "Россия",
            "US": "США",
            "DE": "Германия",
            "FR": "Франция",
            "CN": "Китай",
            "JP": "Япония",
            "GB": "Великобритания",
            "KZ": "Казахстан",
            "TR": "Турция",
            "UA": "Украина",
            "LV": "Латвия"
        ]
        
        return countries[code.uppercased()] ?? code
    }
    
    private func updateDisconnectedState() {
        currentIP = "Нет подключения"
        countryName = "Офлайн"
        countryCode = ""
        iconName = "❌"
    }
    
    private func handleError() {
        // Не сбрасываем isConnected при ошибке, если сеть физически подключена
        // Это позволяет различать отсутствие интернета и ошибку запроса
        // isConnected будет обновлен через NWPathMonitor
        updateDisconnectedState()
    }
}
