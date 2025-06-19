import SwiftUI

struct HomeHubNotConnectedView: View {
    var body: some View {
        Text("Your HomeHub is not connected")
            .font(.title2)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .padding(.bottom)
        Text("Please connect your HomePod on the HomeApp to your primary home to continue")
            .padding()
        
        
    }
}

#Preview {
    HomeHubNotConnectedView()
}
