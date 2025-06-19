//import BackgroundTasks
//import UIKit
//
//class AppDelegate: UIResponder, UIApplicationDelegate {
//
//    func application(_ application: UIApplication,
//                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//
//        // Register background task
//        BGTaskScheduler.shared.register(
//            forTaskWithIdentifier: "com.teameleven.HomeDeviceAutomation.refresh",
//            using: nil) { task in
//                self.handleAppRefresh(task: task as! BGAppRefreshTask)
//        }
//
//        return true
//    }
//
//    func handleAppRefresh(task: BGAppRefreshTask) {
//        // 1. Schedule the next fetch
//        scheduleAppRefresh()
//
//        // 2. Expiration handler
//        task.expirationHandler = {
//            task.setTaskCompleted(success: false)
//        }
//
//        // 3. Do your actual background work
//        func handleAppRefresh(task: BGAppRefreshTask) {
//            scheduleAppRefresh()
//
//            task.expirationHandler = {
//                task.setTaskCompleted(success: false)
//            }
//
//            Task {
//                let roomTemp = await HomeKitFetcher.getCurrentTemp()
//
//                guard roomTemp != nil else {
//                    task.setTaskCompleted(success: false)
//                    return
//                }
//
//                if roomTemp! < 20 || roomTemp! > 21 {
//                    let weatherTemp = await WeatherManager.shared.fetchWeather() // returns Double?
//
//                    if let weather = weatherTemp, weather > roomTemp! {
//                        let success = await HomeKitFanController.shared.toggleFanOnThenOff()
//                        print(success ? "Fan toggled" : "Failed to toggle fan")
//                    }
//                }
//
//                task.setTaskCompleted(success: true)
//            }
//        }
//
//    }
//
//    func scheduleAppRefresh() {
//        let request = BGAppRefreshTaskRequest(identifier: "com.yourcompany.myweatherapp.refresh")
//        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // Suggest 30 mins from now
//
//        do {
//            try BGTaskScheduler.shared.submit(request)
//        } catch {
//            print("Failed to schedule background task: \(error)")
//        }
//    }
//}
