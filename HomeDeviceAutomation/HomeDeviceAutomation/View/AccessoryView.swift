import SwiftUI

struct AccessoryView: View {
    
    @StateObject var weatherManager = WeatherManager()
    @ObservedObject var homeKitManager: HomeKitManager
    @ObservedObject var automationViewModel: AutomationViewModel
    @ObservedObject var fanViewModel: FanControllerViewModel
    @ObservedObject var accessoryViewModel: AccessoryViewModel

    
    init(
        homeKitManager: HomeKitManager,
        automationViewModel: AutomationViewModel,
        fanViewModel: FanControllerViewModel,
        accessoryViewModel: AccessoryViewModel
    ) {
        self.homeKitManager = homeKitManager
        self.automationViewModel = automationViewModel
        self.fanViewModel = fanViewModel
        self.accessoryViewModel = accessoryViewModel
    }
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 50)
            
            VStack(alignment: .leading) {
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
                
                HStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(.secondary.opacity(0.7))
                            .frame(width: 150, height: 150)
                        VStack {
                            Text("Outdoor Temperature")
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .frame(width: 150)
                            Text(weatherManager.temperature)
                                .font(.system(size: 48))
                                .bold()
                        }
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(homeKitManager.getTemperature() == nil ? Color.blue : Color.secondary.opacity(0.7))
                            .frame(width: 150, height: 150)
                        if let temp = homeKitManager.getTemperature() {
                                VStack {
                                    Text("Indoor Temperature")
                                        .font(.title3)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 150)
                                        .foregroundColor(.black)
                                    Text(String(format: "%.1f °C", temp))
                                        .font(.system(size: 48))
                                        .bold()
                                }
                            } else {
                                Button(action: {
                                    accessoryViewModel.startSetupFlow()
                                    print("Temperature sensor not connected — tap action triggered")
                                }) {
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
                                // Optional: style button to look like normal content (remove button style)
                                .buttonStyle(PlainButtonStyle())
                            }
                    }
                }
                .padding(.leading)
                if let fan = homeKitManager.getFanAccessories().first {
                    FanView(
                        fanViewModel: fanViewModel,
                        homeKitManager: homeKitManager,
                        automationViewModel: automationViewModel,
                        accessory: fan
                    )

                } else {
                    Text("Exhaust Fan")
                        .font(.title)
                        .padding(.top)
                    Button("Add Exhaust Fan"){
                        accessoryViewModel.startSetupFlow()
                    }
                    .frame(width: 300)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }

            }
            
            Spacer()
        }
        .onAppear {
            guard let home = homeKitManager.selectedHome else { return }

            let onTriggerName = "Turn Fan On Trigger Above 25.0°C"
            let offTriggerName = "Turn Fan Off Trigger Below 20.0°C"

            if automationViewModel.existingTrigger(named: onTriggerName, in: home) == nil {
                automationViewModel.setupFanAutomation(for: home, lowerBound: 20.0, upperBound: 25.0, turnFanOn: true)
            }

            if automationViewModel.existingTrigger(named: offTriggerName, in: home) == nil {
                automationViewModel.setupFanAutomation(for: home, lowerBound: 20.0, upperBound: 25.0, turnFanOn: false)

            }
            
            weatherManager.requestWeather()
            //automationViewModel.startObservingFanState(for: home)
        }

    }
}

//#Preview {
//    AccessoryConnectedView()
//}
