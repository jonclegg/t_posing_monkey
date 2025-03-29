//
//  tposing_monkey_appApp.swift
//  tposing_monkey_app
//
//  Created by Jonathan Clegg on 3/29/25.
//

import SwiftUI

@main
struct tposing_monkey_appApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
