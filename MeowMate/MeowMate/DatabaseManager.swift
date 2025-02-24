import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?

    private init() {
        do {
            // 使用FileManager来获取文档目录路径
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let databasePath = documentDirectory.appendingPathComponent("meowmate.sqlite3").path
            db = try Connection(databasePath)
            createTables()
        } catch {
            print("无法连接到数据库: \(error)")
        }
    }

    private func createTables() {
        // 创建表的代码
    }

    // 添加更多数据库操作方法
} 