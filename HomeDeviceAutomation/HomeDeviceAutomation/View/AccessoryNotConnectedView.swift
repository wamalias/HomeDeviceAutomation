import SwiftUI

struct AccessoryNotConnectedView: View {
    @StateObject private var weatherManager = WeatherManager()
    @StateObject private var homeKitManager = HomeKitManager()

    var body: some View {
        Spacer()
            .frame (height: 50)
        VStack (alignment: .leading){
            if let primaryHome = homeKitManager.selectedHome {
                    Text(primaryHome.name)
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom)
                } else {
                    Text("No Primary Home")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom)
                }
            HStack (spacing: 20){
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(.secondary.opacity(0.7))
                        .frame(width: 150, height: 150)
                    VStack {
                        Text("Outdoor Temperature")
                            .font(.title3)
                        //.bold()
                            .multilineTextAlignment(.center)
                            .frame(width: 150)
                        Text(weatherManager.temperature)
                            .font(.system(size: 48))
                            .bold()
                        
                    }
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(.blue)
                        .frame(width: 150, height: 150)
                    VStack {
                        Text("Add Indoor Temperature Sensor")
                            .font(.title3)
                        // .bold()
                            .multilineTextAlignment(.center)
                            .frame(width: 150)
                            .foregroundStyle(.white)
                            .padding(.bottom)
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                            .font(.system(size: 20))
                    }
                }
            }
            Text("Exhaust Fan")
                .font(.title)
                .padding(.top)
            Button("Add Exhaust Fan"){
                
            }
            .frame(width: 300)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(20)
            
        }
        Spacer()
        
//        VStack(spacing: 20) {
//            Text("Current Weather")
//                .font(.largeTitle)
//                .bold()
//
//            Text(weatherManager.temperature)
//                .font(.system(size: 64))
//                .bold()
//
//            Text(weatherManager.condition)
//                .font(.title2)
//            
//            Text(weatherManager.isDaylight ? "Day" : "Night")
//                .font(.headline)
//                .foregroundColor(weatherManager.isDaylight ? .orange : .blue)
//            
//            Text(weatherManager.UVIndex)
//                .font(.headline)
//
//            Button("Refresh") {
//                weatherManager.requestWeather()
//            }
//            .padding()
//            .background(Color.blue)
//            .foregroundColor(.white)
//            .cornerRadius(10)
//        }
//        .padding()
//        .onAppear {
//            weatherManager.requestWeather()
//        }
    }
}

#Preview {
    AccessoryNotConnectedView()
}
