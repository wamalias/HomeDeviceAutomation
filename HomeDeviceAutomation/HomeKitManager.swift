import HomeKit
import Combine
import Foundation

class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate, HMAccessoryDelegate {
    @Published var home: [HMHome] = []
    @Published var selectedHome: HMHome? = nil
    @Published var rooms: [HMRoom] = []
    @Published var accessories: [HMAccessory] = []
    @Published var homeHubState: HMHomeHubState = .notAvailable
    @Published var automation: [HMTrigger] = []
    var temperatures: [UUID: Double] = [:]
    @Published var homeTemperature: Double? = nil
    @Published var fanPowerStates: [UUID: Bool] = [:]
    
    private var homeManager: HMHomeManager!
    
    override init() {
        super.init()
        homeManager = HMHomeManager()
        homeManager.delegate = self
    }
    
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        home = manager.homes
        
        if let firstHome = home.first {
            selectHome(homeName: firstHome.name)
        }
    }
    
    func selectHome(homeName : String){
        
        for home in self.home {
            if (home.name == homeName){
                selectedHome = home
                accessories = home.accessories
                homeHubState = home.homeHubState
                automation = home.triggers
                homeHubState = home.homeHubState
            }
        }
//        homeTemperature = temperatures[home.uniqueIdentifier]
//        readRoomTemperature()
//        readExhaustFan()
//        setupFanAutomation(for: home)
    }
    
    func readRoomTemperature() {
        guard let home = selectedHome else { return }
        
        for accessory in accessories {
            accessory.delegate = self
            
            if let tempService = accessory.services.first(where: { $0.serviceType == HMServiceTypeTemperatureSensor }) {
                if let tempCharacteristic = tempService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }) {
                    tempCharacteristic.enableNotification(true) { error in
                        if let error = error {
                            print("Error enabling notification: \(error.localizedDescription)")
                        }
                        print("Live temperature update enabled")
                    }
                    tempCharacteristic.readValue { error in
                        if let error = error {
                            print("Error reading value: \(error.localizedDescription)")
                        }
                        else if let currentTemperature = tempCharacteristic.value as? NSNumber {
                            DispatchQueue.main.async {
                                self.temperatures[home.uniqueIdentifier] = currentTemperature.doubleValue
                                print("Current temperature: \(currentTemperature.doubleValue)°C")
                            }
                        }
                    }
                    return
                }
            }
        }
        print("No temperature sensors found")
    }
    
    func readExhaustFan() {
        print("🔍 Reading exhaust fan...")

        // Step 1: Ambil semua accessories yang punya service FAN
        let fanAccessories = accessories.filter { accessory in
            accessory.services.contains(where: { $0.serviceType == HMServiceTypeFan })
        }

        guard !fanAccessories.isEmpty else {
            print("❌ No exhaust fan accessories found")
            return
        }

        print("✅ Found \(fanAccessories.count) fan accessories")

        // Step 2: Loop fanAccessories dan baca power state-nya
        for accessory in fanAccessories {
            accessory.delegate = self

            let fanServices = accessory.services.filter {
                $0.serviceType == HMServiceTypeFan
            }

            for fanService in fanServices {
                let powerCharacteristics = fanService.characteristics.filter {
                    $0.characteristicType == HMCharacteristicTypePowerState
                }

                for characteristic in powerCharacteristics {
                    // Aktifkan notifikasi
                    characteristic.enableNotification(true) { error in
                        if let error = error {
                            print("❌ Error enabling notification: \(error.localizedDescription)")
                        } else {
                            print("✅ Live fan update enabled for \(accessory.name)")
                        }
                    }

                    // Baca nilai power
                    characteristic.readValue { error in
                        if let error = error {
                            print("❌ Error reading power state: \(error.localizedDescription)")
                        } else if let isOn = characteristic.value as? Bool {
                            print("💨 Fan '\(accessory.name)' is \(isOn ? "ON" : "OFF")")

                            DispatchQueue.main.async {
                                self.fanPowerStates[accessory.uniqueIdentifier] = isOn
                            }
                        } else {
                            print("⚠️ Could not interpret power state for \(accessory.name)")
                        }

                        print("📦 fanPowerStates now: \(self.fanPowerStates)")
                    }
                }
            }
        }
    }

    
    func getExhaustFanPowerState(for accessory: HMAccessory) -> Bool? {
        return fanPowerStates[accessory.uniqueIdentifier]
    }
    
    func setFanPowerState(for accessory: HMAccessory, isOn: Bool) {
        print("Setting exhaust fan power to \(isOn ? "ON" : "OFF")")
        guard let fanService = accessory.services.first(where: { $0.serviceType == HMServiceTypeFan }) else {
            print("Fan service not found in accessory \(accessory.name)")
            return
        }

        guard let powerCharacteristic = fanService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) else {
            print("Power characteristic not found in fan service")
            return
        }

        powerCharacteristic.writeValue(isOn) { error in
            if let error = error {
                print("Error setting fan power: \(error.localizedDescription)")
            } else {
                print("Fan power set to \(isOn ? "ON" : "OFF")")
                DispatchQueue.main.async {
                    self.fanPowerStates[accessory.uniqueIdentifier] = isOn
                }
            }
        }
    }
    
    func createFanScene(name: String, turnOn: Bool, for accessory: HMAccessory, completion: @escaping (HMActionSet?) -> Void) {
        print("Creating scene \(name)")
        guard let home = self.selectedHome else {
            print("❌ No selected home")
            completion(nil)
            return
        }
        
        guard let fanService = accessory.services.first(where: { $0.serviceType == HMServiceTypeFan }),
              let powerChar = fanService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) else {
            print("❌ Fan service or power characteristic not found")
            completion(nil)
            return
        }
        
        let action = HMCharacteristicWriteAction(characteristic: powerChar, targetValue: NSNumber(value: turnOn))
        
        home.addActionSet(withName: name) { actionSet, error in
            if let error = error {
                print("❌ Error creating scene: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let actionSet = actionSet else {
                completion(nil)
                return
            }
            
            actionSet.addAction(action) { error in
                if let error = error {
                    print("❌ Error adding action to scene: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    print("✅ Scene '\(name)' created with fan \(turnOn ? "ON" : "OFF")")
                    completion(actionSet)
                }
            }
        }
    }
    
    
    func createTemperatureTrigger(for home: HMHome, scene: HMActionSet, temperatureThreshold: Double) {
        print("Creating temperature trigger...")
        guard let tempAccessory = home.accessories.first(where: {
            $0.services.contains(where: { $0.serviceType == HMServiceTypeTemperatureSensor })
        }),
        let tempService = tempAccessory.services.first(where: {
            $0.serviceType == HMServiceTypeTemperatureSensor
        }),
        let currentTempCharacteristic = tempService.characteristics.first(where: {
            $0.characteristicType == HMCharacteristicTypeCurrentTemperature
        }) else {
            print("❌ No temperature sensor or characteristic found.")
            return
        }

        let triggerName = "\(scene.name) Trigger at \(temperatureThreshold)°C"
        if home.triggers.contains(where: { $0.name == triggerName }) {
            print("⚠️ Trigger '\(triggerName)' already exists.")
            return
        }

        let tempEvent = HMCharacteristicEvent(characteristic: currentTempCharacteristic, triggerValue: NSNumber(value: temperatureThreshold))
        let trigger = HMEventTrigger(name: triggerName, events: [tempEvent], predicate: nil)

        home.addTrigger(trigger) { error in
            if let error = error {
                print("❌ Failed to add temperature trigger: \(error.localizedDescription)")
            } else {
                trigger.addActionSet(scene) { error in
                    if let error = error {
                        print("❌ Failed to link scene to trigger: \(error.localizedDescription)")
                    } else {
                        print("✅ Trigger '\(triggerName)' created and linked to scene '\(scene.name)'")
                    }
                }
            }
        }
    }
   
//    func setupFanAutomation(for home: HMHome, temperatureThreshold: Double, condition: Bool) {
//            let sceneName = condition == true? "Open Window" : "Close Window"
//
//            var scene: HMActionSet?
//            if let existingScene = home.actionSets.first(where: { $0.name == sceneName }) {
//                scene = existingScene
//            } else {
//                createFanScene(for: home, turnOn: condition)
//                // But need to wait or reload home.actionSets after async creation
//                scene = home.actionSets.first(where: { $0.name == sceneName })
//            }
//
//            // Create trigger only if scene exists
//            if let scene = scene {
//                createTemperatureTrigger(for: home, scene: scene, temperatureThreshold: temperatureThreshold)
//            } else {
//                print("Scene '\(sceneName)' not found, cannot create trigger.")
//            }
//        }


    func setupFanAutomation(for home: HMHome) {
        print("Setting up fan automation...")
        var exhaustFanAccessories: [HMAccessory] = []
        var exhaustFanServices: [HMService] = []

        for accessory in accessories {
            accessory.delegate = self
            
            let fanServices = accessory.services.filter {
                $0.serviceType == HMServiceTypeFan
            }
            
            if !fanServices.isEmpty {
                exhaustFanAccessories.append(accessory)
                exhaustFanServices.append(contentsOf: fanServices)
            }
        }
        
        guard let fanAccessory = exhaustFanAccessories.first else {
            print("❌ No exhaust fan accessory found.")
            return
        }

        let isOn = getExhaustFanPowerState(for: fanAccessory) ?? false
        let sceneName = isOn ? "Fan OFF Scene" : "Fan ON Scene"

        createFanScene(name: sceneName, turnOn: isOn, for: fanAccessory) { scene in
            if let scene = scene {
                // Scene berhasil dibuat
                if sceneName == "Fan ON Scene" {
                    self.createTemperatureTrigger(for: home, scene: scene, temperatureThreshold: 25.00)
                } else{
                    self.createTemperatureTrigger(for: home, scene: scene, temperatureThreshold: 20.0)
                }
            } else {
                // Coba cari scene yang sudah ada
                if let existingScene = home.actionSets.first(where: { $0.name == sceneName }) {
                    print("⚠️ Scene already exists, using existing one: \(sceneName)")
                    if sceneName == "Fan ON Scene" {
                        self.createTemperatureTrigger(for: home, scene: existingScene, temperatureThreshold: 25.00)
                    } else{
                        self.createTemperatureTrigger(for: home, scene: existingScene, temperatureThreshold: 20.0)
                    }
                } else {
                    print("❌ Failed to create or find scene: \(sceneName)")
                }
            }
        }
    }

}
