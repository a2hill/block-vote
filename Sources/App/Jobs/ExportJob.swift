//
//  ExportJob.swift
//  
//
//  Created by Austin Hill on 2/28/21.
//

import Vapor
import Queues
import Fluent

@available(OSX 10.15.4, *)
struct ExportJob: ScheduledJob {
    let VOTES_CHUNK_SIZE = 64 // Arbitrary chunk size. Should probably do some calculations
    
    let filePath: String
    let fileManager: FileManager
    
    init(filePath: String) {
        self.filePath = filePath
        self.fileManager = FileManager()
    }

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        do {
            // Need to ensure there is no existing file as we don't want to concatinate
            try removeFile()
        } catch {
            context.logger.critical("Skipping export. Error occured while removing previous file: \(error)")
            return context.eventLoop.future()
        }
        
        guard let file = createFile(logger: context.logger) else {
            context.logger.critical("Skipping export. Failed to create file")
            return context.eventLoop.future()
        }
        
        do {
            try file.write(contentsOf: Vote.csvHeader.data(using: .utf8)!)
        } catch {
            context.logger.critical("Skipping export. Failed to write header to file")
            return context.eventLoop.future()
        }
        
        var buff: String = ""
        var exportError: Error?
        
        return Vote.query(on: context.application.db).chunk(max: VOTES_CHUNK_SIZE) { queryResults in
            guard exportError == nil else { return }
            
            do {
                try queryResults.forEach { result in
                    let csvString = try result.get().toCsvString()
                    buff.append(csvString)
                }
                try file.write(contentsOf: buff.data(using: .utf8)!)
                buff = ""
            } catch {
                context.logger.critical("Error occured while exporting votes: \(error)")
                exportError = error
            }
        }.guard({exportError == nil}, else: exportError!)
        .always {_ in
            file.closeFile()
        }
    }
    
    func createFile(logger: Logger? = nil) -> FileHandle? {
        // Prevent calling create for a file that already exists. This will cause overwrite which could lead to unpredictable behavior
        guard !fileManager.fileExists(atPath: self.filePath) else {
            logger?.error("Cannot create file: already exists")
            return nil
        }
        fileManager.createFile(atPath: self.filePath, contents: nil)
        return FileHandle(forWritingAtPath: self.filePath)
    }
    
    func removeFile(logger: Logger? = nil) throws {
        guard fileManager.fileExists(atPath: self.filePath) else { return }
        try fileManager.removeItem(atPath: self.filePath)
    }
}

extension Vote {
    public static let csvHeader: String = "address, candidate, quantity, signature\n"
    
    public func toCsvString() throws -> String {
        return "\(id!), \(candidate), \(quantity), \(signature)\n"
    }
}
