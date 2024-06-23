//
//  ContentView.swift
//  InfiniteAppStoreiOS
//
//  Created by nate parrott on 6/16/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView(.vertical) {
            AppMenuView()
                .padding()
        }
        .background(Color.gray95)
    }
}

#Preview {
    ContentView()
}
