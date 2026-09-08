//
//  SwiftUIView.swift
//  AdmobLibrary
//
//  Created by Tien Nguyen on 8/7/26.
//

import SwiftUI

struct SwiftUIView: View {
    
    @State var isNextScreen = false
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .onTapGesture {
                loadAndShowInter(configKey: "INTER_HOME") {
                    print("✅ INTER_HOME close")
                    isNextScreen = true
                }
            }
            .navigationDestination(isPresented: $isNextScreen) {
                SecondView()
            }
    }
}

#Preview {
    SwiftUIView()
}
