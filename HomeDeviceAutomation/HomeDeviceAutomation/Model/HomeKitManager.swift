import Foundation
import HomeKit
import Combine

class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate, HMAccessoryDelegate {
    @Published var selectedHome: HMHome?
    @Published var accessories: [HMAccessory] = []
    @Published var temperature: Double? = nil
    @Published var homeHubState: HMHomeHubState = .notAvailable
    
    var fanControllerViewModel: FanControllerViewModel?

        init(fanControllerViewModel: FanControllerViewModel) {
            super.init()
            self.fanControllerViewModel = fanControllerViewModel
            homeManager = HMHomeManager()
            homeManager.delegate = self
        }
    
    private var homeManager: HMHomeManager!

    override init() {
        super.init()
        homeManager = HMHomeManager()
        homeManager.delegate = self
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        guard let firstHome = manager.homes.first else {
            print("No HomeKit homes available.")
            return
        }
        selectHome(firstHome)
        homeHubState = firstHome.homeHubState
    }

    private func selectHome(_ home: HMHome) {
        selectedHome = home
        accessories = home.accessories
        observeTemperature()
    }

//    private func observeTemperature() {
//        guard let home = selectedHome else { return }
//        
//        for accessory in home.accessories {
//            accessory.delegate = self
//            
//            guard let tempService = accessory.services.first(where: { $0.serviceType == HMServiceTypeTemperatureSensor }),
//                  let tempChar = tempService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }) else { continue }
//            
//            tempChar.enableNotification(true) { error in
//                if let error = error {
//                    print("Error enabling temperature notification: \(error.localizedDescription)")
//                }
//            }
//            
//            tempChar.readValue { [weak self] error in
//                if let value = tempChar.value as? NSNumber {
//                    DispatchQueue.main.async {
//                        self?.temperature = value.doubleValue
//                    }
//                }
//            }
//        }
//    }
    
    private func observeTemperature() {
            guard let home = selectedHome else { return }
            
            for accessory in home.accessories {
                accessory.delegate = self
                
                guard let tempService = accessory.services.first(where: { $0.serviceType == HMServiceTypeTemperatureSensor }),
                      let tempChar = tempService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }) else { continue }
                
                // Enable notifications for temperature changes
                tempChar.enableNotification(true) { error in
                    if let error = error {
                        print("Error enabling temperature notification: \(error.localizedDescription)")
                    }
                }
                
                // Initial read
                tempChar.readValue { [weak self] error in
                    if let value = tempChar.value as? NSNumber {
                        DispatchQueue.main.async {
                            self?.temperature = value.doubleValue
                        }
                    }
                }
            }
        }

        // This delegate method is called when a characteristic value changes
    // Inside HomeKitManager when fan characteristic changes:
    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        if characteristic.characteristicType == HMCharacteristicTypePowerState {
            if let isOn = characteristic.value as? Bool {
                DispatchQueue.main.async {
                    // Notify fanViewModel about the new state
                    self.fanControllerViewModel?.updateFanState(accessory, isOn: isOn)
                }
            }
        }
        // Temperature updates handled as before
        if characteristic.characteristicType == HMCharacteristicTypeCurrentTemperature {
            if let value = characteristic.value as? NSNumber {
                DispatchQueue.main.async {
                    self.temperature = value.doubleValue
                }
            }
        }
    }


    func getFanAccessories() -> [HMAccessory] {
        return accessories.filter {
            $0.services.contains(where: { $0.serviceType == HMServiceTypeFan })
        }
    }

    func getTemperature() -> Double? {
        return temperature
    }
    
    func getAccessories() {
            guard let home = selectedHome else { return }
            accessories = home.accessories
        }
}
