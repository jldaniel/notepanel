import Foundation
import OSLog
import SwiftData

enum AppModel {
    static let logger = Logger(subsystem: "com.notepanel.app", category: "persistence")

    /// True when the persistent store could not be opened and notes will not survive relaunch.
    private(set) static var isInMemoryFallback = false

    /// App-scoped store directory; resolves inside the app container when sandboxed.
    static let storeDirectoryURL: URL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("NotePanel", isDirectory: true)

    static let storeURL = storeDirectoryURL.appendingPathComponent("Notes.store")

    static let container: ModelContainer = {
        let schema = Schema([Note.self])
        do {
            try FileManager.default.createDirectory(
                at: storeDirectoryURL,
                withIntermediateDirectories: true
            )
            let config = ModelConfiguration(schema: schema, url: storeURL)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            logger.fault("Could not create persistent ModelContainer: \(error, privacy: .public)")
            isInMemoryFallback = true
            do {
                let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [memoryConfig])
            } catch {
                // In-memory container creation performs no I/O; nothing can run without it.
                fatalError("Could not create in-memory ModelContainer: \(error)")
            }
        }
    }()
}

extension ModelContext {
    /// Saves the context, logging and reporting failures via `.persistenceErrorOccurred`
    /// instead of silently dropping them.
    @discardableResult
    func saveOrReport() -> Bool {
        do {
            try save()
            return true
        } catch {
            AppModel.logger.error("Failed to save model context: \(error, privacy: .public)")
            NotificationCenter.default.post(name: .persistenceErrorOccurred, object: nil)
            return false
        }
    }
}
