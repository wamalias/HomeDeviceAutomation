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
    
    func fetchUVIndex(for location: CLLocation) async throws -> Int {
        let weatherService = WeatherService()
        let weather = try await weatherService.weather(for: location)
        return weather.currentWeather.uvIndex.value
    }
    
    func fetchTemperature(for location: CLLocation) async throws -> Double {
        let weatherService = WeatherService()
        let weather = try await weatherService.weather(for: location)
        let temperatureCelsius = weather.currentWeather.temperature.converted(to: .celsius)
        return temperatureCelsius.value
    }
    
    func isDaytime(for location: CLLocation) async throws -> Bool {
        let weatherService = WeatherService()
        let weather = try await weatherService.weather(for: location)
        return weather.currentWeather.isDaylight
    }

    private func fetchWeather(for location: CLLocation) {
        Task {
            do {
                let weather = try await service.weather(for: location)
                await MainActor.run {
                    self.temperature = String(format: "%.0fº", weather.currentWeather.temperature.value)
                    self.condition = weather.currentWeather.condition.description
                    self.isDaylight = weather.currentWeather.isDaylight
                    self.UVIndex = String(format: "%0f", weather.currentWeather.uvIndex.value)
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
