//
//  PushView.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import SwiftUI

struct PushView: View {
    let templateStore: PushTemplateStore
    @State private var isPresentingCompose = false
    @State private var composingTemplate: PushMessageTemplate?

    var body: some View {
        NavigationStack {
            Group {
                if templateStore.templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates Yet",
                        systemImage: "doc.on.doc",
                        description: Text("Save push message templates here. They are stored on this device.")
                    )
                } else {
                    List {
                        Section("Templates") {
                            ForEach(templateStore.templates) { template in
                                Button {
                                    composingTemplate = template
                                    isPresentingCompose = true
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(template.name)
                                            .foregroundStyle(.primary)
                                        Text("Saved on this device")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        templateStore.delete(ids: [template.id])
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Push")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Compose", systemImage: "square.and.pencil") {
                        composingTemplate = nil
                        isPresentingCompose = true
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingCompose) {
            ComposePushView(template: composingTemplate, templateStore: templateStore)
        }
    }
}

#Preview {
    PushView(templateStore: PushTemplateStore())
}
