//
//  StaqqApp.swift
//  Staqq
//
//  Created by Hayashi Ryosuke on 2026/01/13.
//

import SwiftUI
import SwiftData

@main
struct StaqqApp: App {
    @State private var showSplash = true
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DocumentCard.self,
            AppTag.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else {
                MainView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

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
                    .font(.custom("Avenir Next", size: 40))
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
