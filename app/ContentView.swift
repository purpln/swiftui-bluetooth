//
//  ContentView.swift
//  app
//
//  Created by Sergey Romanenko on 26.10.2020.
//

import SwiftUI

struct ContentView: View {
    @State var presented = false
    @ObservedObject var ble = BLEConnection()
    @State var slide:Float = 0
    var value:Binding<Float>{
        Binding<Float>(
            get: {
                self.slide
            }, set: {value in
                ble.data[1] = toBytes(value)
                self.slide = value
            }
        )
    }
    
    var body: some View {
        home
    }
    
    var home: some View{
        VStack{
            HStack{
                Button(action: {presented.toggle()}) {
                    Text("connect").padding().overlay(RoundedRectangle(cornerRadius: 15).stroke(colorChange(ble.connected), lineWidth: 2))
                }.sheet(isPresented: $presented) {
                    actions(ble: ble, connectedColor: colorChange(ble.connected), presented: $presented)
                }
            }
            HStack{
                Button(action: {
                    ble.data[0] = 0x01
                }){
                    Text("on").padding().overlay(RoundedRectangle(cornerRadius: 15).stroke(colorChange(ble.connected), lineWidth: 2))
                }
                Button(action: {
                    ble.data[0] = 0
                }){
                    Text("off").padding().overlay(RoundedRectangle(cornerRadius: 15).stroke(colorChange(ble.connected), lineWidth: 2))
                }
            }
            //Slider(value: value, in: 0...100, step: 2).padding().overlay(RoundedRectangle(cornerRadius: 15).stroke(colorChange(ble.connected), lineWidth: 2))
            HStack{
                //Text(ble.text).foregroundColor(colorChange(ble.connected))
                Spacer()
            }
        }.padding().accentColor(colorChange(ble.connected))
    }
    func write(_ value:Float){
        ble.data[0] = toBytes(value)
    }
}

func colorChange(_ connected:Bool) -> Color{
    if connected{
        return Color.green
    }else{
        return Color.blue
    }
}

struct actions: View{
    @ObservedObject var ble:BLEConnection
    var connectedColor:Color
    @Binding var presented:Bool
    var body: some View{
            VStack{
                HStack{
                    Button(action: { ble.disconnect() }){
                        if ble.connected{
                            Text("disconnect").font(.title2)
                        }
                    }
                    Spacer()
                    Button(action: { presented.toggle() }){
                        Image(systemName: "xmark.circle").font(.title)
                    }
                }.padding()
                HStack{
                    Text("connected to \(ble.name)").font(.title).foregroundColor(connectedColor)
                    Spacer()
                }.padding(.horizontal)
                List(ble.peripherals) { peripheral in
                    Button(action: {
                        ble.number = peripheral.id
                        ble.connect()
                        presented.toggle()
                    }){
                        Text(peripheral.name)
                    }
                }.listStyle(InsetGroupedListStyle()).onAppear{self.ble.startScanning()}.onDisappear{self.ble.stopScanning()}
                Spacer()
            }.accentColor(connectedColor)
    }
}

func toBytes(_ value:Float) -> UInt8{
    return UInt8( value )
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
