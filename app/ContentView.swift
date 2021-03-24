//
//  ContentView.swift
//  app
//
//  Created by Sergey Romanenko on 26.10.2020.
//

import SwiftUI

struct ContentView: View {
    @State var presented: Bool = false
    
    var body: some View {
        Button("connect"){ presented.toggle() }.sheet(isPresented: $presented){ Action(presented: $presented) }
    }
}

struct Action: View {
    var bluetooth = Bluetooth.shared
    @Binding var presented: Bool
    @State var list = [Bluetooth.Device]()
    
    var body: some View {
        HStack{
            Button("disconnect"){ bluetooth.disconnect() }.padding()
            Spacer()
        }
        List(list){ peripheral in
            Button(peripheral.peripheral.name ?? ""){ bluetooth.connect(peripheral.peripheral) }
        }.listStyle(InsetGroupedListStyle()).onAppear{
            bluetooth.delegate = self
            bluetooth.startScanning()
        }.onDisappear{ bluetooth.stopScanning() }
    }
}

extension Action: BluetoothProtocol {
    func state(state: Bluetooth.State) { }
    
    func list(list: [Bluetooth.Device]) { self.list = list }
    
    func value(data: Data) { }
}
