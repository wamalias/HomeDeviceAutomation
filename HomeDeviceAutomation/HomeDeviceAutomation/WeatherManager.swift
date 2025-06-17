import Foundation
import WeatherKit
import CoreLocation

class WeatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let service = WeatherService()
    private let locationManager = CLLocationManager()

    @Published var temperature: String = "--"
    @Published var condition: String = "Unknown"
    @Published var isDaylight: Bool = true
    @Published var UVIndex: String = "--"


    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestWeather() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            useFallbackLocation()
            return
        }
        fetchWeather(for: location)
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        useFallbackLocation()
    }

    private func useFallbackLocation() {
        //surabaya
        let fallback = CLLocation(latitude: 7.2575, longitude: 112.7521)
        fetchWeather(for: fallback)
    }

    func fetchUVIndex(from weather: Weather) -> Int {
        return weather.currentWeather.uvIndex.value
    }

    func fetchTemperature(from weather: Weather) -> Double {
        return weather.currentWeather.temperature.converted(to: .celsius).value
    }

    func isDaylight(from weather: Weather) -> Bool {
        return weather.currentWeather.isDaylight
    }

    private func fetchWeather(for location: CLLocation) {
        Task {
            do {
                let weather = try await service.weather(for: location)
                
                let temperature = fetchTemperature(from: weather)
                let condition = weather.currentWeather.condition.description
                let isDay = isDaylight(from: weather)
                let uv = fetchUVIndex(from: weather)
                
                await MainActor.run {
                    self.temperature = String(format: "%.0fº", temperature)
                    self.condition = condition
                    self.isDaylight = isDay
                    self.UVIndex = String(uv)
                }
            } catch {
                print("WeatherKit error: \(error)")
                await MainActor.run {
                    self.temperature = "--"
                    self.condition = "Error"
                    self.isDaylight = true
                    self.UVIndex = "--"
                }
            }
        }
    }

}
