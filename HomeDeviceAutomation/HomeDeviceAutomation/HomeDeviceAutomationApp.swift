//import SwiftUI
//
//@main
//struct HomeDeviceAutomationApp: App {
//    var body: some Scene {
//        WindowGroup {
//            AccessoryConnectedView()
//        }
//    }
//}

//import SwiftUI
//
//@main
//struct HomeDeviceAutomationApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}


import SwiftUI


@main
struct HomeDeviceAutomationApp: App {
    
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

    
    var body: some Scene {
        WindowGroup {
            AccessoryView(
                homeKitManager: homeKitManager,
                automationViewModel: automationViewModel,
                fanViewModel: fanViewModel,
                accessoryViewModel: AccessoryViewModel(homeKitManager: homeKitManager)
            )
        }
    }
}

//@main
//struct MyWeatherApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .onAppear {
//                    appDelegate.scheduleAppRefresh()
//                }
//        }
//    }
//}
