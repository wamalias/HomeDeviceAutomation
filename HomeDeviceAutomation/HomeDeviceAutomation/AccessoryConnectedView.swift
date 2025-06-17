//
//  AccessoryConnectedView.swift
//  HomeDeviceAutomation
//
//  Created by Gabriella Natasya Pingky Davis on 17/06/25.
//

import SwiftUI

struct AccessoryConnectedView: View {
    
    @StateObject private var weatherManager = WeatherManager()
    
    var body: some View {
        Spacer()
            .frame (height: 50)
        VStack (alignment: .leading){
            Text("My Home")
                .font(.largeTitle)
                .bold()
                .padding(.bottom)
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
                        Text(weatherManager.temperature).font(.system(size: 48))   .bold()
                        
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
                        Text(weatherManager.temperature).font(.system(size: 48))   .bold()
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
    AccessoryConnectedView()
}
