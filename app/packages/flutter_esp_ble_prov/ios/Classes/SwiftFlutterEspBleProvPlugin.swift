import Flutter
import UIKit
import ESPProvision

public class SwiftFlutterEspBleProvPlugin: NSObject, FlutterPlugin {
    private let SCAN_BLE_DEVICES = "scanBleDevices"
    private let SCAN_WIFI_NETWORKS = "scanWifiNetworks"
    private let PROVISION_WIFI = "provisionWifi"
    private let SEND_CUSTOM_DATA = "sendCustomData"
    private let DISCONNECT_DEVICE = "disconnectDevice"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_esp_ble_prov", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterEspBleProvPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let provisionService = BLEProvisionService(result: result);
        let arguments = call.arguments as! [String: Any]
        
        if(call.method == SCAN_BLE_DEVICES) {
            let prefix = arguments["prefix"] as! String
            provisionService.searchDevices(prefix: prefix)
        } else if(call.method == SCAN_WIFI_NETWORKS) {
            let deviceName = arguments["deviceName"] as! String
            let proofOfPossession = arguments["proofOfPossession"] as! String
            provisionService.scanWifiNetworks(deviceName: deviceName, proofOfPossession: proofOfPossession)
        } else if (call.method == PROVISION_WIFI) {
            let deviceName = arguments["deviceName"] as! String
            let proofOfPossession = arguments["proofOfPossession"] as! String
            let ssid = arguments["ssid"] as! String
            let passphrase = arguments["passphrase"] as! String
            provisionService.provision(
                deviceName: deviceName,
                proofOfPossession: proofOfPossession,
                ssid: ssid,
                passphrase: passphrase
            )
        } else if (call.method == SEND_CUSTOM_DATA) {
            let deviceName = arguments["deviceName"] as! String
            let proofOfPossession = arguments["proofOfPossession"] as! String
            let path = arguments["path"] as! String
            let data: Data
            if let typedData = arguments["data"] as? FlutterStandardTypedData {
                data = typedData.data
            } else {
                data = Data()
            }
            provisionService.sendCustomData(
                deviceName: deviceName,
                proofOfPossession: proofOfPossession,
                path: path,
                data: data
            )
        } else if (call.method == DISCONNECT_DEVICE) {
            let deviceName = arguments["deviceName"] as! String
            provisionService.disconnectDevice(deviceName: deviceName)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
}

protocol ProvisionService {
    var result: FlutterResult { get }
    func searchDevices(prefix: String) -> Void
    func scanWifiNetworks(deviceName: String, proofOfPossession: String) -> Void
    func provision(deviceName: String, proofOfPossession: String, ssid: String, passphrase: String) -> Void
    func sendCustomData(deviceName: String, proofOfPossession: String, path: String, data: Data) -> Void
    func disconnectDevice(deviceName: String) -> Void
}

private class BLEProvisionService: ProvisionService {
    fileprivate var result: FlutterResult
    
    // Static connection cache — mirrors Android's Boss.activeDevice pattern so
    // multiple calls (scanWifi → fetchSerial → sendClaimToken) reuse the same session.
    static var activeDevice: ESPDevice? = nil
    static var connectedDeviceName: String? = nil
    
    init(result: @escaping FlutterResult) {
        self.result = result
    }
    
    func searchDevices(prefix: String) {
        ESPProvisionManager.shared.searchESPDevices(devicePrefix: prefix, transport:.ble, security:.unsecure) { deviceList, error in
            if(error != nil) {
                ESPErrorHandler.handle(error: error!, result: self.result)
            }
            self.result(deviceList?.map({ (device: ESPDevice) -> String in
                return device.name
            }))
        }
    }
    
    func scanWifiNetworks(deviceName: String, proofOfPossession: String) {
        self.connect(deviceName: deviceName, proofOfPossession: proofOfPossession) {
            device in
            device?.scanWifiList { wifiList, error in
                if(error != nil) {
                    NSLog("Error scanning wifi networks, deviceName: \(deviceName) ")
                    ESPErrorHandler.handle(error: error!, result: self.result)
                }
                self.result(wifiList?.map({(networks: ESPWifiNetwork) -> String in return networks.ssid}))
                // Do NOT disconnect here — keep session alive for subsequent sendCustomData calls
            }
        }
    }
    
    func provision(deviceName: String, proofOfPossession: String, ssid: String, passphrase: String) {
        self.connect(deviceName: deviceName, proofOfPossession: proofOfPossession){
            device in
            device?.provision(ssid: ssid, passPhrase: passphrase) { status in
                switch status {
                case .success:
                    NSLog("Success provisioning device. ssid: \(ssid), deviceName: \(deviceName) ")
                    self.result(true)
                case .configApplied:
                    NSLog("Wifi config applied device. ssid: \(ssid), deviceName: \(deviceName) ")
                case .failure:
                    NSLog("Failed to provision device. ssid: \(ssid), deviceName: \(deviceName) ")
                    self.result(false)
                }
            }
        }
    }
    
    func sendCustomData(deviceName: String, proofOfPossession: String, path: String, data: Data) {
        self.connect(deviceName: deviceName, proofOfPossession: proofOfPossession) { device in
            let sendData = data.isEmpty ? Data([0x00]) : data
            device?.sendData(path: path, data: sendData) { responseData, error in
                if let error = error {
                    NSLog("sendCustomData failed: path=\(path) error=\(error)")
                    self.result(FlutterError(
                        code: "SEND_CUSTOM_DATA_FAILED",
                        message: error.description,
                        details: nil
                    ))
                } else {
                    NSLog("sendCustomData success: path=\(path) responseSize=\(responseData?.count ?? 0)")
                    if let responseData = responseData {
                        self.result(FlutterStandardTypedData(bytes: responseData))
                    } else {
                        self.result(nil)
                    }
                }
            }
        }
    }
    
    func disconnectDevice(deviceName: String) {
        NSLog("disconnectDevice: \(deviceName)")
        BLEProvisionService.activeDevice?.disconnect()
        BLEProvisionService.activeDevice = nil
        BLEProvisionService.connectedDeviceName = nil
        self.result(nil)
    }
    
    private func connect(deviceName: String, proofOfPossession: String, completionHandler: @escaping (ESPDevice?) -> Void) {
        // Reuse existing session if already connected to the same device
        if let active = BLEProvisionService.activeDevice, BLEProvisionService.connectedDeviceName == deviceName {
            NSLog("connect: reusing existing session for \(deviceName)")
            completionHandler(active)
            return
        }
        
        // Disconnect any previous device
        BLEProvisionService.activeDevice?.disconnect()
        BLEProvisionService.activeDevice = nil
        BLEProvisionService.connectedDeviceName = nil
        
        ESPProvisionManager.shared.createESPDevice(deviceName: deviceName, transport: .ble, security: .unsecure, proofOfPossession: proofOfPossession) { espDevice, error in
            
            if(error != nil) {
                ESPErrorHandler.handle(error: error!, result: self.result)
                return
            }
            espDevice?.connect { status in
                switch status {
                case .connected:
                    BLEProvisionService.activeDevice = espDevice
                    BLEProvisionService.connectedDeviceName = deviceName
                    completionHandler(espDevice!)
                case let .failedToConnect(error):
                    ESPErrorHandler.handle(error: error, result: self.result)
                default:
                    self.result(FlutterError(code: "DEVICE_DISCONNECTED", message: nil, details: nil))
                }
            }
        }
    }
    
}

private class ESPErrorHandler {
    static func handle(error: ESPError, result: FlutterResult) {
        result(FlutterError(code: String(error.code), message: error.description, details: nil))
    }
}
