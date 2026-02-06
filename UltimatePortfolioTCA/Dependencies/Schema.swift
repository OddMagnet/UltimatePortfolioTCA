import Dependencies
import os
import SQLiteData

private nonisolated let logger = Logger(
    subsystem: "dev.oddmagnet.UltimatePortfolio",
    category: "Database"
)

extension DependencyValues {
    private func databaseConfiguration() -> Configuration {
        var configuration = Configuration()
        configuration.foreignKeysEnabled = true
        configuration.prepareDatabase { db in
            try db.attachMetadatabase()
            #if DEBUG
                db.trace(options: .profile) {
                    guard
                        !SyncEngine.isSynchronizing,
                        !$0.expandedDescription.hasPrefix("--")
                    else { return }
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

    mutating func bootstrapDatabase() throws {
        let database = try SQLiteData.defaultDatabase(configuration: databaseConfiguration())

        var migrator = DatabaseMigrator()
        #if DEBUG
            migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("Create 'issues', 'tags', and 'issueTags' tables") { db in
            try #sql("""
                CREATE TABLE "issues" (
                    "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                    "title" TEXT NOT NULL DEFAULT '',
                    "detail" TEXT NOT NULL DEFAULT '',
                    "priority" INTEGER,
                    "completed" INTEGER NOT NULL DEFAULT 0,
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
                CREATE TRIGGER "trigger_issues_update_modified"
                AFTER UPDATE ON "issues"
                FOR EACH ROW
                WHEN OLD."modified" IS NEW."modified"
                BEGIN
                    UPDATE "issues" SET "modified" = datetime('subsec')
                    WHERE "id" = OLD."id";
                END
                """)
                .execute(db)
        }

        try migrator.migrate(database)
        defaultDatabase = database
        defaultSyncEngine = try SyncEngine(
            for: database,
            tables: Issue.self, Tag.self, IssueTag.self
        )
    }
}
