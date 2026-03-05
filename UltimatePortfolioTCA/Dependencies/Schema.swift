import os
import SQLiteData

private nonisolated let logger = Logger(
    subsystem: "dev.oddmagnet.UltimatePortfolio",
    category: "Database"
)

extension DependencyValues {
    /// Configures the SQLite database: enables foreign keys, attaches the metadatabase for
    /// iCloud sharing support, and sets up SQL query tracing in debug builds.
    private func databaseConfiguration() -> Configuration {
        var configuration = Configuration()
        configuration.foreignKeysEnabled = true
        configuration.prepareDatabase { db in
            try db.attachMetadatabase()
            #if DEBUG
                db.trace(options: .profile) {
                    guard !SyncEngine.isSynchronizing, !$0.expandedDescription.hasPrefix("--") else { return }
                    switch context {
                    case .live:
                        logger.debug("\($0.expandedDescription)")
                    case .preview:
                        print($0.expandedDescription)
                    case .test:
                        break
                    }
                }
            #endif
        }
        return configuration
    }

    /// Sets up the full database stack: creates or opens the database, runs migrations,
    /// initializes ``SyncEngine`` for iCloud sync, registers the `modified` trigger,
    /// and seeds sample data (debug only). Must be called via `prepareDependencies` at app launch.
    mutating func bootstrapDatabase() throws {
        let database = try SQLiteData.defaultDatabase(configuration: databaseConfiguration())

        var migrator = DatabaseMigrator()
        #if DEBUG
            migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("Create 'issues', 'tags', and 'issueTags' tables", migrate: createTables)

        try migrator.migrate(database)
        defaultSyncEngine = try SyncEngine(
            for: database,
            tables: Issue.self, Tag.self, IssueTag.self
        )
        try database.write(createTriggers)

        #if DEBUG
            try database.seedSampleData()
        #endif
        defaultDatabase = database
    }

    // MARK: - Tables

    private func createTables(in db: Database) throws {
        try #sql("""
        CREATE TABLE "issues" (
            "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
            "title" TEXT NOT NULL DEFAULT '',
            "detail" TEXT NOT NULL DEFAULT '',
            "priority" INTEGER NOT NULL DEFAULT 0,
            "isCompleted" INTEGER NOT NULL DEFAULT 0,
            "created" TEXT NOT NULL DEFAULT (datetime('subsec')),
            "modified" TEXT
        ) STRICT
        """)
        .execute(db)

        try #sql("""
        CREATE TABLE "tags" (
            "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
            "name" TEXT NOT NULL DEFAULT '' COLLATE NOCASE
        ) STRICT
        """)
        .execute(db)

        try #sql("""
        CREATE TABLE "issueTags" (
            "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
            "issueID" TEXT NOT NULL REFERENCES "issues"("id") ON DELETE CASCADE,
            "tagID" TEXT NOT NULL REFERENCES "tags"("id") ON DELETE CASCADE
        ) STRICT
        """)
        .execute(db)
        try #sql("""
        CREATE INDEX "index_issueTags_on_issueID" ON "issueTags"("issueID")
        """)
        .execute(db)
        try #sql("""
        CREATE INDEX "index_issueTags_on_tagID" ON "issueTags"("tagID")
        """)
        .execute(db)

        try #sql("""
        CREATE VIRTUAL TABLE "issueTexts" USING fts5(
            title,
            detail,
            content="issues",
            content_rowid="rowid"
        )
        """)
        .execute(db)
    }

    // MARK: - Triggers

    private func createTriggers(in db: Database) throws {
        try Issue.createTemporaryTrigger(
            after: .update(touch: \.modified) { _, _ in
                !SyncEngine.$isSynchronizing
            }
        ).execute(db)

        // FTS5: keep "issueTexts" in sync with "issues"
        try #sql("""
        CREATE TEMPORARY TRIGGER "fts_issues_after_insert"
        AFTER INSERT ON "issues"
        BEGIN
            INSERT INTO "issueTexts"("rowid", "title", "detail")
            VALUES (NEW."rowid", NEW."title", NEW."detail");
        END
        """)
        .execute(db)

        try #sql("""
        CREATE TEMPORARY TRIGGER "fts_issues_after_update"
        AFTER UPDATE OF "title", "detail" ON "issues"
        BEGIN
            INSERT INTO "issueTexts"("issueTexts", "rowid", "title", "detail")
            VALUES ('delete', OLD."rowid", OLD."title", OLD."detail");
            INSERT INTO "issueTexts"("rowid", "title", "detail")
            VALUES (NEW."rowid", NEW."title", NEW."detail");
        END
        """)
        .execute(db)

        try #sql("""
        CREATE TEMPORARY TRIGGER "fts_issues_after_delete"
        AFTER DELETE ON "issues"
        BEGIN
            INSERT INTO "issueTexts"("issueTexts", "rowid", "title", "detail")
            VALUES ('delete', OLD."rowid", OLD."title", OLD."detail");
        END
        """)
        .execute(db)
    }
}
