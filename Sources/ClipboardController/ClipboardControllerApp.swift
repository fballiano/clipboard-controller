import SwiftUI

@main
struct ClipboardControllerApp: App {
    @State private var model: AppModel

    init() {
        let model = AppModel.shared
        model.bootstrap()
        _model = State(initialValue: model)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.menu)
    }
}
