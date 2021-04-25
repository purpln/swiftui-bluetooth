//
//  ContentView.swift
//  app
//
//  Created by Sergey Romanenko on 26.10.2020.
//

import SwiftUI

struct ContentView: View {
    var bluetooth = Bluetooth.shared
    @State var presented: Bool = false
    @State var list = [Bluetooth.Device]()
    @State var isConnected: Bool = Bluetooth.shared.current != nil { didSet { if isConnected { presented.toggle() } } }
    
    @State var response = Data()
    @State var string: String = ""
    @State var value: Float = 0
    @State var state: Int = 0 { didSet { bluetooth.send([toBytes(state)]) } }
    
    var body: some View {
        VStack{
            HStack{
                Button("scan"){ presented.toggle() }.buttonStyle(appButton()).padding()
                Spacer()
            }
            if isConnected {
                Slider(value: Binding( get: { value }, set: {(newValue) in sendValue(newValue) } ), in: 0...100).padding(.horizontal)
                Button("toggle"){ sendState() }.buttonStyle(appButton())
                TextField("", text: $string).onChange(of: string){ bluetooth.send(Array($0.utf8)) }
                Text("returned byte value from \(bluetooth.current?.name ?? ""): \(response.hex)")
                Text("returned string: \(String(data: response, encoding: .utf8) ?? "")")
            }
            Spacer()
        }.sheet(isPresented: $presented){ Action(bluetooth: bluetooth, presented: $presented, list: $list, isConnected: $isConnected) }
            .onAppear{ bluetooth.delegate = self }
    }
    
    func sendState() { if state == 0 { state = 1 } else { state = 0} }
    
    func sendValue(_ value: Float) {
        if Int(value) != Int(self.value) {
            guard let sendValue = map(Int(value), of: 0...100, to: 0...255) else { return }
            bluetooth.send([toBytes(state), toBytes(sendValue)])
        }
        self.value = value
    }
    
    func map(_ value: Int, of: ClosedRange<Int>, to: ClosedRange<Int>) -> Int? {
        guard let ofmin = of.min(), let ofmax = of.max(), let tomin = to.min(), let tomax = to.max() else { return nil }
        return Int(tomin + (tomax - tomin) * (value - ofmin) / (ofmax - ofmin))
    }
    
    func toBytes(_ value: Int) -> UInt8 { UInt8( value ) }
}

extension ContentView: BluetoothProtocol {
    func state(state: Bluetooth.State) {
        switch state {
        case .unknown: print("◦ .unknown")
        case .resetting: print("◦ .resetting")
        case .unsupported: print("◦ .unsupported")
        case .unauthorized: print("◦ bluetooth disabled, enable it in settings")
        case .poweredOff: print("◦ turn on bluetooth")
        case .poweredOn: print("◦ everything is ok")
        case .error: print("• error")
        case .connected:
            print("◦ connected to \(bluetooth.current?.name ?? "")")
            isConnected = true
        case .disconnected:
            print("◦ disconnected")
            isConnected = false
        }
    }
    
    func list(list: [Bluetooth.Device]) { self.list = list }
    
    func value(data: Data) { response = data }
}

struct Action: View {
    var bluetooth: Bluetooth
    @Binding var presented: Bool
    @Binding var list: [Bluetooth.Device]
    @Binding var isConnected: Bool { didSet { if isConnected { presented.toggle() } } }
    
    var body: some View {
        HStack {
            Spacer()
            if isConnected {
                Text("connected to \(bluetooth.current?.name ?? "")")
            }
            Spacer()
            Button(action: { presented.toggle() }){
                Color(UIColor.secondarySystemBackground).overlay(
                    Image(systemName: "multiply").foregroundColor(Color(UIColor.systemGray))
                ).frame(width: 30, height: 30).cornerRadius(15)
            }.padding([.horizontal, .top]).padding(.bottom, 8)
        }
        if isConnected {
            HStack {
                Button("disconnect"){ bluetooth.disconnect() }.buttonStyle(appButton()).padding([.horizontal])
                Spacer()
            }
        }
        List(list){ peripheral in
            Button(peripheral.peripheral.name ?? ""){ bluetooth.connect(peripheral.peripheral) }
        }.listStyle(InsetGroupedListStyle()).onAppear{
            bluetooth.startScanning()
        }.onDisappear{ bluetooth.stopScanning() }.padding(.vertical, 0)
    }
}
