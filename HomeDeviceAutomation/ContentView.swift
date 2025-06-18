//import SwiftUI
//import HomeKit
//
//struct ContentView: View {
//    @StateObject private var homeKitManager = HomeKitManager()
//    
//    var body: some View {
//        NavigationView {
//            List {
//                // Homes Section
//                Section(header: Text("Homes")) {
//                    ForEach(homeKitManager.home, id: \.uniqueIdentifier) { home in
//                        Button(action: {
//                            homeKitManager.selectHome(home)
//                        }) {
//                            HStack {
//                                Text(home.name)
//                                if homeKitManager.selectedHome == home {
//                                    Spacer()
//                                    Image(systemName: "checkmark")
//                                }
//                            }
//                        }
//                    }
//                }
//                
//                // Accessories Section
//                if let selectedHome = homeKitManager.selectedHome {
//                    Section(header: Text("Accessories in \(selectedHome.name)")) {
//                        ForEach(homeKitManager.accessories, id: \.uniqueIdentifier) { accessory in
//                            VStack(alignment: .leading, spacing: 8) {
//                                Text(accessory.name)
//                                    .font(.headline)
//                                
//                                // Kontrol FAN (On/Off)
//                                if accessory.services.contains(where: { $0.serviceType == HMServiceTypeFan }) {
//                                    if let fanService = accessory.services.first(where: { $0.serviceType == HMServiceTypeFan }),
//                                       let _ = fanService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) {
//                                        Toggle("Fan Power", isOn: Binding(
//                                            get: {
//                                                homeKitManager.fanPowerStates[accessory.uniqueIdentifier] ?? false
//                                            },
//                                            set: { newValue in
//                                                homeKitManager.setFanPowerState(for: accessory, isOn: newValue)
//                                            }
//                                        ))
//                                    }
//                                }
//                            }
//                            .padding(.vertical, 4)
//                        }
//                    }
//                }
//                
//                // Temperature Section
//                Section(header: Text("Current Temperature")) {
//                    if let temp = homeKitManager.homeTemperature {
//                        Text(String(format: "%.1f °C", temp))
//                            .font(.largeTitle)
//                    } else {
//                        Text("No temperature data")
//                    }
//                }
//            }
//            .listStyle(InsetGroupedListStyle())
//            .navigationTitle("HomeKit Manager")
//            .onAppear {
//                // Select the first home automatically
//                if let firstHome = homeKitManager.home.first {
//                    homeKitManager.selectHome(firstHome)
//                }
//            }
//        }
//    }
//}
//

//
//  AccessoryConnectedView.swift
//  HomeDeviceAutomation
//
//  Created by Gabriella Natasya Pingky Davis on 17/06/25.
//

import SwiftUI

struct AccessoryConnectediew: View {
    
    //@StateObject private var weatherManager = WeatherManager()
    @StateObject private var homeKitManager = HomeKitManager()
   
    var body: some View {
        Spacer()
            .frame (height: 50)
        VStack (alignment: .leading){
            if let selectedHome = homeKitManager.selectedHome{
                Text(selectedHome.name)
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
//                        Text(weatherManager.temperature).font(.system(size: 48))   .bold()
                        
                    }
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(.secondary.opacity(0.7))
                        .frame(width: 150, height: 150)
                    
                    VStack {
                        Text("Indoor Temperature")
                            .font(.title3)
                        // .bold()
                            .multilineTextAlignment(.center)
                            .frame(width: 150)
                            .foregroundStyle(.black)
                            //.padding(.bottom)
                        if let roomTemperature = homeKitManager.{
                            Text(roomTemperature)
                                .font(.system(size: 48))   .bold()
                        }
//                        Text(weatherManager.temperature).font(.system(size: 48))   .bold()
                    }
                }
            }
            .padding(.leading)
            Text("Exhaust Fan")
                .font(.title)
                .padding(.top)
            Toggle("Power", isOn: .constant(true))
                .frame(width: 350)
                //.padding()
            Toggle("Automation", isOn: .constant(true))
                .frame(width: 350)
                //.padding()
            Text ("*Your exhaust fan will automatically turn on when the room temperature is higher than the outdoor temperature.")
                .frame(width: 350)
                .font(.caption)
                .foregroundStyle(.secondary)

        }
        Spacer()
    }
}

#Preview {
    AccessoryConnectediew()
}
