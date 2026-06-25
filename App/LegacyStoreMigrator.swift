import Foundation
import SwiftData

/// One-time import of notes from the legacy shared SwiftData default store
/// (`~/Library/Application Support/default.store`) into the app-scoped store.
///
/// The legacy files are only ever read (enforced by the sandbox's read-only
/// temporary exception); they are stage-copied into the container so SQLite
/// can perform WAL recovery on writable files, then notes are row-copied with
/// ID dedupe so a partially completed run is safe to retry.
enum LegacyStoreMigrator {
    private static let markerName = ".legacy-migration-v1"

    static func migrateIfNeeded(into container: ModelContainer, storeDirectory: URL) {
        let fileManager = FileManager.default
        let marker = storeDirectory.appendingPathComponent(markerName)
        guard !fileManager.fileExists(atPath: marker.path) else { return }

        guard let legacyStore = legacyStoreCandidates()
            .first(where: { fileManager.fileExists(atPath: $0.path) }) else {
            writeMarker(at: marker)
            return
        }

        do {
            let staging = try stageCopy(of: legacyStore, into: storeDirectory)
            defer { try? fileManager.removeItem(at: staging.directory) }
            let imported = try importNotes(fromStoreAt: staging.storeURL, into: container)
            writeMarker(at: marker)
            AppModel.logger.notice(
                "Imported \(imported) notes from legacy store at \(legacyStore.path, privacy: .public)"
            )
        } catch {
            AppModel.logger.error(
                "Legacy store migration failed (will retry next launch): \(error, privacy: .public)"
            )
            NotificationCenter.default.post(name: .persistenceErrorOccurred, object: nil)
        }
    }

    private static func legacyStoreCandidates() -> [URL] {
        guard let home = realHomeDirectoryURL() else { return [] }
        let appSupport = home
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
        // Never self-migrate: in unsandboxed debug runs the new store also lives in the real home.
        return [appSupport.appendingPathComponent("default.store")].filter {
            $0.standardizedFileURL.path != AppModel.storeURL.standardizedFileURL.path
        }
    }

    /// The user's real home directory; `NSHomeDirectory()` points into the
    /// sandbox container, where the legacy store never lived.
    private static func realHomeDirectoryURL() -> URL? {
        guard let passwd = getpwuid(getuid()), let home = passwd.pointee.pw_dir else {
            return nil
        }
        return URL(fileURLWithPath: String(cString: home), isDirectory: true)
    }

    private static func stageCopy(
        of legacyStore: URL,
        into storeDirectory: URL
    ) throws -> (directory: URL, storeURL: URL) {
        let fileManager = FileManager.default
        let stagingDirectory = storeDirectory.appendingPathComponent(
            "migration-staging",
            isDirectory: true
        )
        try? fileManager.removeItem(at: stagingDirectory)
        try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)

        let stagedStore = stagingDirectory.appendingPathComponent(legacyStore.lastPathComponent)
        try fileManager.copyItem(at: legacyStore, to: stagedStore)
        for suffix in ["-wal", "-shm"] {
            let source = URL(fileURLWithPath: legacyStore.path + suffix)
            if fileManager.fileExists(atPath: source.path) {
                try fileManager.copyItem(
                    at: source,
                    to: URL(fileURLWithPath: stagedStore.path + suffix)
                )
            }
        }
        return (stagingDirectory, stagedStore)
    }

    private static func importNotes(
        fromStoreAt stagedURL: URL,
        into container: ModelContainer
    ) throws -> Int {
        let schema = Schema([Note.self])
        let config = ModelConfiguration(schema: schema, url: stagedURL)
        let legacyContainer = try ModelContainer(for: schema, configurations: [config])
        let legacyContext = ModelContext(legacyContainer)
        let legacyNotes = try legacyContext.fetch(
            FetchDescriptor<Note>(sortBy: [SortDescriptor(\.sortIndex)])
        )
        guard !legacyNotes.isEmpty else { return 0 }

        let context = ModelContext(container)
        let existingIDs = Set(try context.fetch(FetchDescriptor<Note>()).map(\.id))
        var imported = 0
        for legacy in legacyNotes where !existingIDs.contains(legacy.id) {
            context.insert(Note(
                id: legacy.id,
                title: legacy.title,
                content: legacy.content,
                sortIndex: legacy.sortIndex,
                colorIndex: legacy.colorIndex,
                isCollapsed: legacy.isCollapsed,
                createdAt: legacy.createdAt,
                updatedAt: legacy.updatedAt
            ))
            imported += 1
        }
        if context.hasChanges {
            try context.save()
        }
        return imported
    }

    private static func writeMarker(at marker: URL) {
        do {
            try Data().write(to: marker)
        } catch {
            AppModel.logger.error("Could not write migration marker: \(error, privacy: .public)")
        }
    }
}
