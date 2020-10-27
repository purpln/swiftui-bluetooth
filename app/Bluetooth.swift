//
//  Bluetooth.swift
//  app
//
//  Created by Sergey Romanenko on 26.10.2020.
//

import CoreBluetooth

class BLEConnection:NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate{
    struct bledevices: Identifiable {
        let id: Int
        let name: String
        let rssi: Int
        let uuid: String
        let peripheral: CBPeripheral
    }
    
    var manager: CBCentralManager!
    var peripheral: CBPeripheral!
    var readCharacteristic: CBCharacteristic?
    var writeCharacteristic: CBCharacteristic?
    var notifyCharacteristic: CBCharacteristic?
    @Published var number = 0
    @Published var name = ""
    @Published var connected = false
    @Published var peripherals = [bledevices]()
    @Published var text = ""
    @Published var data:[UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]{
        didSet{
            send(data)
        }
    }
    @Published var received:[UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    
    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: .none)
        manager.delegate = self
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch manager.state {
        case .unknown:
            print("◦ .unknown")
        case .resetting:
            print("◦ .resetting")
        case .unsupported:
            print("◦ .unsupported")
        case .unauthorized:
            print("◦ u disabled, pls enable it in settings")
        case .poweredOff:
            print("◦ turn on bluetooth")
        case .poweredOn:
            print("◦ everytjing is ok")
        @unknown default:
            print("◦ fatal")
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = String(peripheral.name ?? "unknown")
        let uuid = String(describing: peripheral.identifier)
        let filtered = peripherals.filter{$0.uuid == uuid}
        if filtered.count == 0{
            if name != "unknown"{
                let new = bledevices(id: peripherals.count, name: name, rssi: RSSI.intValue, uuid: uuid, peripheral: peripheral)
                print("• \(new.uuid) \(new.name)")
                peripherals.append(new)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("◦ connected to \(peripheral.name ?? "unknown")")
        connected = true
        name = peripheral.name ?? "unknown"
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error!)
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("◦ \(peripheral.name ?? "unknown") disconnected")
        connected = false
        name = ""
        text = ""
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        var str = "Characteristic"
        guard let characteristics = service.characteristics else{return}
        for characteristic in characteristics{
            switch characteristic.properties {
            case .read:
                print("◦ read")
                readCharacteristic = characteristic
                str += "[r]"
            case .write:
                print("◦ write")
                writeCharacteristic = characteristic
                str += "[w]"
            case .notify:
                print("◦ notify")
                notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                str += "[n]"
            default:
                print("◦ unknown")
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?){}
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){}
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if let value = characteristic.value{
            self.text = value.byte()
        }
    }
    
    func connect(){
        if connected {
            manager.cancelPeripheralConnection(peripheral)
        }else{
            peripheral = peripherals[number].peripheral
            manager.connect(peripheral, options: nil)
        }
    }
    func disconnect(){
        manager.cancelPeripheralConnection(peripheral)
    }
    func startScanning(){
        print("◦ scan")
        peripherals.removeAll()
        manager.scanForPeripherals(withServices: nil, options: nil)
    }
    func stopScanning(){
        print("◦ stop")
        manager.stopScan()
        peripherals.removeAll()
    }
    func write(_ text:String){
        self.text = text
    }
    func send(_ value:[UInt8]){
        guard let characteristic = writeCharacteristic else{return}
        let data = Data(value)
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

extension Data {
    func hex() -> String{
        return map{
            String(format: "%02hhx", $0)
        }.joined()
    }
    func byte() -> String{
        return map{
            String(UInt32($0))
        }.joined()
    }
}
