//
//  HomeHubNotConnectedView.swift
//  HomeDeviceAutomation
//
//  Created by Gabriella Natasya Pingky Davis on 17/06/25.
//

import SwiftUI

struct HomeHubNotConnectedView: View {
    var body: some View {
        Text("Your HomeHub is not connected")
            .font(.title2)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .padding()
        Text("Please connect your HomeHub on the HomeApp  to continue")
        
        
    }
}

#Preview {
    HomeHubNotConnectedView()
}
