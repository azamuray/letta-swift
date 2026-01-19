import Foundation
import Network
import Combine
import AppKit

class WiFiManager: ObservableObject {
    // Published свойства для UI
    @Published var signalStrength: Int = 0 // Процент сигнала (0-100)
    @Published var isConnectedToWiFi: Bool = false
    @Published var wifiName: String = ""
    
    private var updateTimer: Timer?
    private var pathMonitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "WiFiMonitor")
    
    init() {
        print("📡 WiFiManager инициализирован")
        setupPathMonitor()
    }
    
    // Настраиваем мониторинг сети
    private func setupPathMonitor() {
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            // Проверяем используется ли WiFi
            let isWiFi = path.usesInterfaceType(.wifi)
            
            DispatchQueue.main.async {
                self.isConnectedToWiFi = isWiFi
                if !isWiFi {
                    self.signalStrength = 0
                    self.wifiName = ""
                }
            }
        }
        pathMonitor?.start(queue: monitorQueue)
    }
    
    // Запуск мониторинга (вызывается когда меню открывается)
    func startMonitoring() {
        print("🔄 WiFi мониторинг запущен")
        
        // Останавливаем предыдущий таймер если есть
        stopMonitoring()
        
        // Сразу делаем первое измерение
        updateWiFiInfo()
        
        // Обновляем каждую секунду (как просил пользователь)
        // ВАЖНО: Используем common modes, чтобы таймер работал пока мы держим меню открытым
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateWiFiInfo()
        }
        RunLoop.main.add(timer, forMode: .common)
        updateTimer = timer
    }
    
    // Остановка мониторинга (вызывается когда меню закрывается)
    func stopMonitoring() {
        print("⏹️ WiFi мониторинг остановлен")
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // Обновление информации о WiFi
    private func updateWiFiInfo() {
        guard isConnectedToWiFi else {
            return
        }
        
        // Используем system_profiler для получения WiFi информации
        executeSystemProfiler()
    }
    
    // Выполняем system_profiler для получения WiFi информации
    private func executeSystemProfiler() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        task.arguments = ["SPAirPortDataType", "-detailLevel", "basic"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe() // Игнорируем ошибки
        
        do {
            try task.run()
            
            // Ждем завершения в фоне
            DispatchQueue.global(qos: .utility).async { [weak self] in
                task.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    self?.parseSystemProfilerOutput(output)
                }
            }
        } catch {
            print("❌ Ошибка выполнения system_profiler: \(error)")
            // Фоллбэк - показываем фиксированное значение если подключены к WiFi
            DispatchQueue.main.async {
                if self.isConnectedToWiFi {
                    self.signalStrength = 75 // Средний уровень по умолчанию
                    self.wifiName = "WiFi"
                }
            }
        }
    }
    
    // Парсим вывод system_profiler
    private func parseSystemProfilerOutput(_ output: String) {
        var rssi = 0
        var ssid = ""
        
        // Ищем строку "Signal / Noise: -XX dBm / -YY dBm"
        let lines = output.components(separatedBy: "\n")
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Ищем название сети (строка перед "PHY Mode")
            if trimmed.contains("PHY Mode:") && index > 0 {
                let previousLine = lines[index - 1].trimmingCharacters(in: .whitespaces)
                // Убираем двоеточие в конце если есть
                if previousLine.hasSuffix(":") {
                    ssid = String(previousLine.dropLast())
                }
            }
            
            // Ищем сигнал
            if trimmed.contains("Signal / Noise:") || trimmed.contains("Signal:") {
                // Формат: "Signal / Noise: -63 dBm / -91 dBm" или "Signal: -63 dBm"
                let components = trimmed.components(separatedBy: ":")
                if components.count >= 2 {
                    let signalPart = components[1].trimmingCharacters(in: .whitespaces)
                    // Извлекаем первое число (RSSI)
                    let parts = signalPart.components(separatedBy: " ")
                    if let firstValue = parts.first, let value = Int(firstValue) {
                        rssi = value
                    }
                }
            }
        }
        
        let percentage = rssiToPercentage(rssi)
        
        print("📶 WiFi: \(ssid.isEmpty ? "Connected" : ssid) | RSSI: \(rssi) dBm | Качество: \(percentage)%")
        
        DispatchQueue.main.async {
            self.wifiName = ssid.isEmpty ? "WiFi" : ssid
            self.signalStrength = percentage
        }
    }
    
    // Конвертация RSSI (dBm) в проценты
    private func rssiToPercentage(_ rssi: Int) -> Int {
        guard rssi != 0 else {
            // Если RSSI = 0, возвращаем средний уровень
            return isConnectedToWiFi ? 75 : 0
        }
        
        // RSSI обычно находится в диапазоне от -90 (очень плохо) до -30 (отлично)
        let minRSSI = -90
        let maxRSSI = -30
        
        // Ограничиваем значение в допустимом диапазоне
        let clampedRSSI = max(minRSSI, min(maxRSSI, rssi))
        
        // Вычисляем процент (от 0 до 100)
        let percentage = ((clampedRSSI - minRSSI) * 100) / (maxRSSI - minRSSI)
        
        return max(0, min(100, percentage))
    }
    
    deinit {
        stopMonitoring()
        pathMonitor?.cancel()
        print("🗑️ WiFiManager деинициализирован")
    }
}
