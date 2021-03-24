//
//  Bluetooth.swift
//  app
//
//  Created by Sergey Romanenko on 26.10.2020.
//

import CoreBluetooth

protocol BluetoothProtocol {
    func state(state: Bluetooth.State)
    func list(list: [Bluetooth.Device])
    func value(data: Data)
}

final class Bluetooth: NSObject {
    static let shared = Bluetooth()
    var delegate: BluetoothProtocol?
    
    var peripherals = [Device]()
    var current: CBPeripheral?
    
    private var manager: CBCentralManager?
    private var readCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    
    private override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: .none)
        manager?.delegate = self
    }
    
    func connect(_ peripheral: CBPeripheral) {
        if current != nil {
            guard let current = current else { return }
            manager?.cancelPeripheralConnection(current)
        } else { manager?.connect(peripheral, options: nil) }
    }
    
    func disconnect() {
        guard let current = current else { return }
        manager?.cancelPeripheralConnection(current)
    }
    
    func startScanning() {
        peripherals.removeAll()
        manager?.scanForPeripherals(withServices: nil, options: nil)
    }
    func stopScanning() {
        peripherals.removeAll()
        manager?.stopScan()
    }
    func send(_ value: [UInt8]) {
        guard let characteristic = writeCharacteristic else { return }
        current?.writeValue(Data(value), for: characteristic, type: .withResponse)
    }
    
    enum State { case unknown, resetting, unsupported, unauthorized, poweredOff, poweredOn, error }
    
    struct Device: Identifiable {
        let id: Int
        let rssi: Int
        let uuid: String
        let peripheral: CBPeripheral
    }
}

extension Bluetooth: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch manager?.state {
        case .unknown: delegate?.state(state: .unknown)
        case .resetting: delegate?.state(state: .resetting)
        case .unsupported: delegate?.state(state: .unsupported)
        case .unauthorized: delegate?.state(state: .unauthorized)
        case .poweredOff: delegate?.state(state: .poweredOff)
        case .poweredOn: delegate?.state(state: .poweredOn)
        default: delegate?.state(state: .error)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let uuid = String(describing: peripheral.identifier)
        let filtered = peripherals.filter{$0.uuid == uuid}
        if filtered.count == 0{
            guard let _ = peripheral.name else { return }
            let new = Device(id: peripherals.count, rssi: RSSI.intValue, uuid: uuid, peripheral: peripheral)
            print(advertisementData)
            peripherals.append(new)
            delegate?.list(list: peripherals)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) { print(error!) }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) { self.current = nil }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.current = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
}

extension Bluetooth: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        var str = "Characteristic"
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            switch characteristic.properties {
            case .read:
                readCharacteristic = characteristic
                str += "[r]"
            case .write:
                writeCharacteristic = characteristic
                str += "[w]"
            case .notify:
                notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                str += "[n]"
            default: break
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) { }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) { }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else { return }
        delegate?.value(data: value)
    }
}

extension Data {
    func hex() -> String{
        map{ String(format: "%02hhx", $0) }.joined()
    }
    
    var byte: String { map{ String(UInt32($0)) }.joined() }
}
