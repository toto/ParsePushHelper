//
//  PushView.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import SwiftUI

/// Identifiable wrapper for compose context: new message or editing a template.
/// Using this with `sheet(item:)` ensures the correct template is passed when opening a template.
private struct ComposeSheetItem: Identifiable {
    let id: String
    let template: PushMessageTemplate?
}

struct PushView: View {
    let templateStore: PushTemplateStore
    @State private var composeSheetItem: ComposeSheetItem?

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
                        ForEach(templateStore.templates) { template in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.name)
                                    .foregroundStyle(.primary)
                                Text("Saved on this device")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                composeSheetItem = ComposeSheetItem(id: template.id.uuidString, template: template)
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
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") {
                        composeSheetItem = ComposeSheetItem(id: UUID().uuidString, template: nil)
                    }
                }
            }
        }
        .sheet(item: $composeSheetItem, onDismiss: { composeSheetItem = nil }) { item in
            ComposePushView(template: item.template, templateStore: templateStore)
        }
    }
}

#Preview {
    PushView(templateStore: PushTemplateStore())
}
