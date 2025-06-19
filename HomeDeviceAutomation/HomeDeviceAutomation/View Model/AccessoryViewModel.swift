import Foundation
import HomeKit
import Combine

class AccessoryViewModel: NSObject, ObservableObject, HMAccessoryBrowserDelegate {
    @Published var foundAccessories: [HMAccessory] = []
    @Published var isAddingAccessory: Bool = false
    @Published var errorMessage: String?

    private let accessoryBrowser = HMAccessoryBrowser()
    private let homeKitManager: HomeKitManager

    init(homeKitManager: HomeKitManager) {
        self.homeKitManager = homeKitManager
        super.init()
        accessoryBrowser.delegate = self
    }
    
    func startSetupFlow() {
        let setupManager = HMAccessorySetupManager()
        let request = HMAccessorySetupRequest()

        setupManager.performAccessorySetup(using: request) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Accessory setup failed: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                } else if let result = result {
                    print("Accessory setup succeeded: \(result)")
                    self?.homeKitManager.getAccessories()
                } else {
                    self?.errorMessage = "Unknown error during accessory setup."
                    print("Accessory setup failed with unknown error.")
                }
            }
        }
    }


    func startBrowsing() {
        foundAccessories = []
        accessoryBrowser.startSearchingForNewAccessories()
    }

    func stopBrowsing() {
        accessoryBrowser.stopSearchingForNewAccessories()
    }

    func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
        DispatchQueue.main.async {
            if !self.foundAccessories.contains(where: { $0.uniqueIdentifier == accessory.uniqueIdentifier }) {
                self.foundAccessories.append(accessory)
            }
        }
    }

    func accessoryBrowser(_ browser: HMAccessoryBrowser, didRemoveNewAccessory accessory: HMAccessory) {
        DispatchQueue.main.async {
            self.foundAccessories.removeAll(where: { $0.uniqueIdentifier == accessory.uniqueIdentifier })
        }
    }

    func addAccessory(_ accessory: HMAccessory) {
        guard let home = homeKitManager.selectedHome else {
            errorMessage = "No home selected to add the accessory."
            return
        }

        isAddingAccessory = true
        home.addAccessory(accessory) { [weak self] error in
            DispatchQueue.main.async {
                self?.isAddingAccessory = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    // Update HomeKitManager accessories list if needed
                    self?.homeKitManager.accessories.append(accessory)
                    // Remove from found list (optional)
                    self?.foundAccessories.removeAll(where: { $0.uniqueIdentifier == accessory.uniqueIdentifier })
                }
            }
        }
    }
    
}


