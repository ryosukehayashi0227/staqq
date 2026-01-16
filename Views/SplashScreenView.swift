//
//  SplashScreenView.swift
//  Staqq
//
//  Created by Gemini on 2026/01/14.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        VStack {
            VStack {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.cyan)
                    .shadow(color: .cyan.opacity(0.5), radius: 10, x: 0, y: 5)
                
                Text("Staqq")
                    .font(.custom("Avenir Next", size: 40)) // Custom font if desired, or system
                    .fontWeight(.bold)
                    .foregroundStyle(.primary.opacity(0.80))
                    .padding(.top, 10)
            }
            .scaleEffect(size)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 1.2)) {
                    self.size = 0.9
                    self.opacity = 1.00
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    SplashScreenView()
}
