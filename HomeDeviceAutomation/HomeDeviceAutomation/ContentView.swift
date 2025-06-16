import SwiftUI

struct ContentView: View {
    @StateObject private var weatherManager = WeatherManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("Current Weather")
                .font(.largeTitle)
                .bold()

            Text(weatherManager.temperature)
                .font(.system(size: 64))
                .bold()

            Text(weatherManager.condition)
                .font(.title2)
            
            Text(weatherManager.isDaylight ? "Day" : "Night")
                .font(.headline)
                .foregroundColor(weatherManager.isDaylight ? .orange : .blue)
            
            Text(weatherManager.UVIndex)
                .font(.headline)

            Button("Refresh") {
                weatherManager.requestWeather()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .onAppear {
            weatherManager.requestWeather()
        }
    }
}

#Preview {
    ContentView()
}
