import SwiftUI

struct ContentView: View {
    @StateObject private var homeKitManager = HomeKitManager()
    @StateObject private var automationViewModel = AutomationViewModel()
    @StateObject private var fanViewModel: FanControllerViewModel

    init() {
        let homeKit = HomeKitManager()
        let automationVM = AutomationViewModel()
        _homeKitManager = StateObject(wrappedValue: homeKit)
        _automationViewModel = StateObject(wrappedValue: automationVM)
        _fanViewModel = StateObject(wrappedValue: FanControllerViewModel(homeKitManager: homeKit, automationViewModel: automationVM))
    }

    var body: some View {
        Group {
            switch homeKitManager.homeHubState {
            case .connected:
                AccessoryView(
                    homeKitManager: homeKitManager,
                    automationViewModel: automationViewModel,
                    fanViewModel: fanViewModel,
                    accessoryViewModel: AccessoryViewModel(homeKitManager: homeKitManager)
                )
            default:
                HomeHubNotConnectedView()
            }
        }
        .onAppear {
            if let home = homeKitManager.selectedHome {
                homeKitManager.homeHubState = home.homeHubState
            }

        }
    }
}

#Preview {
    ContentView()
}
