//import HomeKit
//import Combine
//import Foundation
//
//class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate, HMAccessoryDelegate {
//    @Published var home: [HMHome] = []
//    @Published var selectedHome: HMHome? = nil
//    @Published var rooms: [HMRoom] = []
//    @Published var accessories: [HMAccessory] = []
//    @Published var homeHubState: HMHomeHubState = .notAvailable
//    @Published var automation: [HMTrigger] = []
//    var temperatures: [UUID: Double] = [:]
//    @Published var homeTemperature: Double? = nil
//    @Published var fanStates: [UUID: Bool] = [:]
//    @Published var primaryHome: HMHome?
//    
//    private var homeManager: HMHomeManager!
//    
//    override init() {
//        super.init()
//        homeManager = HMHomeManager()
//        homeManager.delegate = self
//    }
//    
//    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
//        home = manager.homes
//        
//        if let firstHome = home.first {
//            selectHome(firstHome)
//            homeHubState = firstHome.homeHubState
//            self.primaryHome = manager.homes.first
//        }
//    }
//    
//    func selectHome(_ home: HMHome){
//        selectedHome = home
//        accessories = home.accessories
//        homeHubState = home.homeHubState
//        automation = home.triggers
//        homeTemperature = temperatures[home.uniqueIdentifier]
//        readRoomTemperature()
//        readFan()
//        setupFanAutomation(for: home, temperatureThreshold: 21.0, turnFanOn: true)
//        setupFanAutomation(for: home, temperatureThreshold: 19.0, turnFanOn: false)
//        
//        
//    }
//    
//    func readRoomTemperature() {
//        guard let home = selectedHome else { return }
//        
//        for accessory in accessories {
//            accessory.delegate = self
//            
//            if let tempService = accessory.services.first(where: { $0.serviceType == HMServiceTypeTemperatureSensor }) {
//                if let tempCharacteristic = tempService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }) {
//                    tempCharacteristic.enableNotification(true) { error in
//                        if let error = error {
//                            print("Error enabling notification: \(error.localizedDescription)")
//                        }
//                        print("Live temperature update enabled")
//                    }
//                    tempCharacteristic.readValue { error in
//                        if let error = error {
//                            print("Error reading value: \(error.localizedDescription)")
//                        }
//                        else if let currentTemperature = tempCharacteristic.value as? NSNumber {
//                            DispatchQueue.main.async {
//                                self.temperatures[home.uniqueIdentifier] = currentTemperature.doubleValue
//                                print("Current temperature: \(currentTemperature.doubleValue)°C")
//                            }
//                        }
//                    }
//                    return
//                }
//            }
//        }
//        print("No temperature sensors found")
//        
//    }
//    
//    func readFan() {
//        for accessory in accessories {
//            accessory.delegate = self
//
//            let fanServices = accessory.services.filter {
//                $0.serviceType == HMServiceTypeFan
//            }
//
//            for fanService in fanServices {
//                let powerCharacteristics = fanService.characteristics.filter {
//                    $0.characteristicType == HMCharacteristicTypePowerState
//                }
//
//                for powerCharacteristic in powerCharacteristics {
//                    powerCharacteristic.enableNotification(true) { error in
//                        if let error = error {
//                            print("Error enabling fan notification: \(error.localizedDescription)")
//                        } else {
//                            print("Live fan update enabled")
//                        }
//                    }
//
//                    powerCharacteristic.readValue { error in
//                        if let error = error {
//                            print("Error reading fan power state: \(error.localizedDescription)")
//                        } else if let isOn = powerCharacteristic.value as? NSNumber {
//                            DispatchQueue.main.async {
//                                self.fanStates[accessory.uniqueIdentifier] = isOn.boolValue
//                                print("Fan is currently \(isOn.boolValue ? "ON" : "OFF")")
//                            }
//                        }
//                    }
//                    return // read one per accessory
//                }
//            }
//        }
//    }
//
//    func setFanState(_ accessory: HMAccessory, to isOn: Bool) {
//        guard let fanService = accessory.services.first(where: { $0.serviceType == HMServiceTypeFan }) else {
//            return
//        }
//
//        guard let powerCharacteristic = fanService.characteristics.first(where: {
//            $0.characteristicType == HMCharacteristicTypePowerState
//        }) else {
//            return
//        }
//
//        powerCharacteristic.writeValue(isOn) { error in
//            if let error = error {
//                print("Error setting fan power state: \(error.localizedDescription)")
//            } else {
//                print("Fan turned \(isOn ? "ON" : "OFF")")
//                DispatchQueue.main.async {
//                    self.fanStates[accessory.uniqueIdentifier] = isOn
//                }
//            }
//        }
//    }
//
//
//    
//    func createFanScene(for home: HMHome, turnOn: Bool, completion: @escaping (HMActionSet?) -> Void) {
//        let sceneName = turnOn ? "Turn Fan On" : "Turn Fan Off"
//        let targetValue = NSNumber(value: turnOn)
//
//        // Find fan accessory
//        guard let fanAccessory = home.accessories.first(where: { accessory in
//            accessory.services.contains(where: { $0.serviceType == HMServiceTypeFan })
//        }) else {
//            print("No fan accessory found.")
//            return
//        }
//
//        // Find fan service
//        guard let fanService = fanAccessory.services.first(where: { $0.serviceType == HMServiceTypeFan }) else {
//            print("No fan service found.")
//            return
//        }
//
//        // Find power state characteristic
//        guard let powerCharacteristic = fanService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) else {
//            print("No power state characteristic found.")
//            return
//        }
//
//        // Check if scene already exists
//        if home.actionSets.contains(where: { $0.name == sceneName }) {
//            print("Scene '\(sceneName)' already exists.")
//            return
//        }
//
//        // Create action set (scene)
//        home.addActionSet(withName: sceneName) { actionSet, error in
//            if let error = error {
//                print("Error creating scene: \(error.localizedDescription)")
//                return
//            }
//
//            guard let actionSet = actionSet else {
//                print("Action set creation failed.")
//                return
//            }
//
//            // Create write action to set fan power state
//            let action = HMCharacteristicWriteAction(characteristic: powerCharacteristic, targetValue: targetValue)
//
//            actionSet.addAction(action) { error in
//                if let error = error {
//                    print("Failed to add action to scene: \(error.localizedDescription)")
//                } else {
//                    print("Scene '\(sceneName)' created successfully with fan power set to \(turnOn ? "On" : "Off")")
//                }
//            }
//        }
//    }
//
//
//
//
//    func createTemperatureTrigger(for home: HMHome, scene: HMActionSet, temperatureThreshold: Double) {
//        guard let tempAccessory = home.accessories.first(where: {
//            $0.services.contains(where: { $0.serviceType == HMServiceTypeTemperatureSensor })
//        }),
//        let tempService = tempAccessory.services.first(where: {
//            $0.serviceType == HMServiceTypeTemperatureSensor
//        }),
//        let currentTempCharacteristic = tempService.characteristics.first(where: {
//            $0.characteristicType == HMCharacteristicTypeCurrentTemperature
//        }) else {
//            print("No temperature sensor or characteristic found.")
//            return
//        }
//
//        let triggerName = "\(scene.name) Trigger at \(temperatureThreshold)°C"
//        if home.triggers.contains(where: { $0.name == triggerName }) {
//            print("Trigger '\(triggerName)' already exists.")
//            return
//        }
//
//        let triggerValue = NSNumber(value: temperatureThreshold)
//        let tempEvent = HMCharacteristicEvent(characteristic: currentTempCharacteristic, triggerValue: triggerValue)
//
//        let eventTrigger = HMEventTrigger(name: triggerName, events: [tempEvent], predicate: nil)
//
//        home.addTrigger(eventTrigger) { error in
//            if let error = error {
//                print("Failed to add temperature trigger: \(error.localizedDescription)")
//            } else {
//                eventTrigger.addActionSet(scene) { error in
//                    if let error = error {
//                        print("Failed to add scene to trigger: \(error.localizedDescription)")
//                    } else {
//                        print("Temperature trigger '\(triggerName)' created and linked to scene '\(scene.name)'.")
//                    }
//                }
//            }
//        }
//    }
//    
//    func setupFanAutomation(for home: HMHome, temperatureThreshold: Double, turnFanOn: Bool) {
//        let sceneName = turnFanOn ? "Turn Fan On" : "Turn Fan Off"
//
//        // Check if scene already exists
//        if let existingScene = home.actionSets.first(where: { $0.name == sceneName }) {
//            // Scene exists, create trigger immediately
//            createTemperatureTrigger(for: home, scene: existingScene, temperatureThreshold: temperatureThreshold)
//        } else {
//            // Create fan scene asynchronously
//            createFanScene(for: home, turnOn: turnFanOn) { createdScene in
//                guard let scene = createdScene else {
//                    print("Failed to create fan scene '\(sceneName)'. Cannot create trigger.")
//                    return
//                }
//                // Now create the temperature trigger for the newly created scene
//                self.createTemperatureTrigger(for: home, scene: scene, temperatureThreshold: temperatureThreshold)
//            }
//        }
//    }
//
//
//
////    func sceneExists(in home: HMHome, named sceneName: String) -> Bool {
////        return home.actionSets.contains { $0.name == sceneName }
////    }
////
////    func triggerExists(in home: HMHome, named triggerName: String) -> Bool {
////        return home.triggers.contains { $0.name == triggerName }
////    }
//
//
//
//}
