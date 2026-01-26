//
//  PushView.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import SwiftUI

struct PushView: View {
    @State private var isPresentingCompose = false

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Pushes Yet",
                systemImage: "paperplane",
                description: Text("Drafts and sent pushes will appear here.")
            )
            .navigationTitle("Push")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Compose", systemImage: "square.and.pencil") {
                        isPresentingCompose = true
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingCompose) {
            ComposePushView()
        }
    }
}

#Preview {
    PushView()
}
