//
//  ScanView.swift
//  app
//
//  Created by Sergey Romanenko on 25.04.2021.
//

import SwiftUI

struct ScanView: View {
    var bluetooth: Bluetooth
    @Binding var presented: Bool
    @Binding var list: [Bluetooth.Device]
    @Binding var isConnected: Bool
    
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
            Button(action: { bluetooth.connect(peripheral.peripheral) }){
                HStack{
                    Text(peripheral.peripheral.name ?? "")
                    Spacer()
                }
                HStack{
                    Text(peripheral.uuid).font(.system(size: 10)).foregroundColor(.gray)
                    Spacer()
                }
            }
        }.listStyle(InsetGroupedListStyle()).onAppear{
            bluetooth.startScanning()
        }.onDisappear{ bluetooth.stopScanning() }.padding(.vertical, 0)
    }
}
