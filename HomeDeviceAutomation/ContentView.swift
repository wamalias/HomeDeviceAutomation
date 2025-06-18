import SwiftUI
import HomeKit

struct ContentView: View {
    @StateObject private var homeKitManager = HomeKitManager()
    
    var body: some View {
        NavigationView {
            List {
                // Homes Section
                Section(header: Text("Homes")) {
                    ForEach(homeKitManager.home, id: \.uniqueIdentifier) { home in
                        Button(action: {
                            homeKitManager.selectHome(home)
                        }) {
                            HStack {
                                Text(home.name)
                                if homeKitManager.selectedHome == home {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                // Accessories Section
                if let selectedHome = homeKitManager.selectedHome {
                    Section(header: Text("Accessories in \(selectedHome.name)")) {
                        ForEach(homeKitManager.accessories, id: \.uniqueIdentifier) { accessory in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(accessory.name)
                                    .font(.headline)
                                
                                // Kontrol FAN (On/Off)
                                if accessory.services.contains(where: { $0.serviceType == HMServiceTypeFan }) {
                                    if let fanService = accessory.services.first(where: { $0.serviceType == HMServiceTypeFan }),
                                       let _ = fanService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) {
                                        Toggle("Fan Power", isOn: Binding(
                                            get: {
                                                homeKitManager.fanPowerStates[accessory.uniqueIdentifier] ?? false
                                            },
                                            set: { newValue in
                                                homeKitManager.setFanPowerState(for: accessory, isOn: newValue)
                                            }
                                        ))
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // Temperature Section
                Section(header: Text("Current Temperature")) {
                    if let temp = homeKitManager.homeTemperature {
                        Text(String(format: "%.1f °C", temp))
                            .font(.largeTitle)
                    } else {
                        Text("No temperature data")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("HomeKit Manager")
            .onAppear {
                // Select the first home automatically
                if let firstHome = homeKitManager.home.first {
                    homeKitManager.selectHome(firstHome)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
