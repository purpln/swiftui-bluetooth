//
//  appApp.swift
//  app
//
//  Created by Sergey Romanenko on 26.10.2020.
//

import SwiftUI

@main
struct appApp: App {
    var bluetooth = Bluetooth.shared
    
    var body: some Scene {
        WindowGroup{
            ContentView().onAppear{ bluetooth.delegate = self }
        }
    }
}

extension appApp: BluetoothProtocol {
    func state(state: Bluetooth.State) {
        switch state {
        case .unknown: print("◦ .unknown")
        case .resetting: print("◦ .resetting")
        case .unsupported: print("◦ .unsupported")
        case .unauthorized: print("◦ bluetooth disabled, enable it in settings")
        case .poweredOff: print("◦ turn on bluetooth")
        case .poweredOn: print("◦ everything is ok")
        case .error: print("• error")
        }
    }
    
    func list(list: [Bluetooth.Device]) { }
    
    func value(data: Data) { }
}
