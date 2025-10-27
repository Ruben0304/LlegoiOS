//
//  ContentView.swift
//  LeegoWatchOS Watch App
//
//  Created by Ruben on 10/27/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingWatchView(isOnboardingCompleted: $hasSeenOnboarding)
            } else if !isLoggedIn {
                LoginWatchView(isLoggedIn: $isLoggedIn)
            } else {
                MainWatchView()
            }
        }
    }
}

#Preview {
    ContentView()
}
