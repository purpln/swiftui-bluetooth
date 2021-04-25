//
//  appApp.swift
//  app
//
//  Created by Sergey Romanenko on 26.10.2020.
//

import SwiftUI

@main
struct appApp: App {
    var body: some Scene {
        WindowGroup{
            ContentView()
        }
    }
}

struct appButton: ButtonStyle {
    let color: Color
    
    public init(color: Color = .accentColor) {
        self.color = color
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundColor(.accentColor)
            .background(Color.accentColor.opacity(0.2))
            .cornerRadius(8)
    }
}
