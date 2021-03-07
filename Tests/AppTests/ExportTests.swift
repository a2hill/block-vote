//
//  ExportTests.swift
//  AppTests
//
//  Created by Austin Hill on 3/2/21.
//

@testable import App
import XCTest
import Vapor
import QueuesFluentDriver

@available(OSX 10.15.4, *)
class ExportTests: XCTestCase {
    
    static let HEADER_LENGTH = 1
    
    let fileManager = FileManager()
    let outputPath = "./votes.csv"
    let scheduleJobDelay = 1.0
    let csvExportDelaySeconds: Int64 = 3
    
    override func setUpWithError() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try setupTestEnvironment(application: app)
        try removeFile()
    }
    
    override func tearDownWithError() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try clearAppState(application: app)
        try removeFile()
    }
    
    func createFile() -> FileHandle? {
        // Prevent calling create for a file that already exists. This will cause overwrite which could lead to unpredictable behavior
        guard !fileManager.fileExists(atPath: self.outputPath) else {
            return nil
        }
        fileManager.createFile(atPath: self.outputPath, contents: nil)
        return FileHandle(forWritingAtPath: self.outputPath)
    }
    
    func removeFile() throws {
        guard fileManager.fileExists(atPath: self.outputPath) else { return }
        try fileManager.removeItem(atPath: self.outputPath)
    }
    
    func testCreateFile() throws {
        let job = ExportJob(filePath: outputPath)
        let file = job.createFile()
        XCTAssertNotNil(file)
        XCTAssertTrue(fileManager.fileExists(atPath: outputPath))
    }
    
    func testCreateDuplicateFile() throws {
        let file = createFile()
        XCTAssertNotNil(file, "Sanity check: remove file if this fails")
        
        let job = ExportJob(filePath: outputPath)
        let secondFile = job.createFile()
        XCTAssertNil(secondFile)
    }
    
    func testRemoveFile() throws {
        let file = createFile()
        XCTAssertNotNil(file, "Sanity check: remove file if this fails")
        
        let job = ExportJob(filePath: outputPath)
        try job.removeFile()
        XCTAssertFalse(fileManager.fileExists(atPath: outputPath))
    }
    
    func testRemoveNonExistantFile() throws {        
        let job = ExportJob(filePath: outputPath)
        try job.removeFile()
        XCTAssertFalse(fileManager.fileExists(atPath: outputPath))
    }

    func testExport() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let votes = try createVotes(on: app.db, for: "test")
        
        app.queues.schedule(ExportJob(filePath: outputPath)).at(Date().addingTimeInterval(scheduleJobDelay))
        try app.queues.startScheduledJobs()
        
        let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
        app.eventLoopGroup.next().scheduleTask(in: .seconds(csvExportDelaySeconds)) { () -> Void in
            let countFuture = Vote.query(on: app.db).all().map {
                $0.count
            }
            let _ = countFuture.flatMapThrowing { [weak self] voteCount in
                XCTAssertEqual(votes.count, voteCount, "Santiy check: Uh oh, these should be equal, check your DB")
                let fileContent = try String(contentsOf: URL(fileURLWithPath: self!.outputPath))
                let lines = fileContent.split(separator: "\n").count - ExportTests.HEADER_LENGTH
                XCTAssertEqual(lines, voteCount)
                promise.succeed(())
            }
        }
        
        try promise.futureResult.wait()
    }
    
    func testExportManyVotes() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let votes = try createVotes(on: app.db, numberOfVotes: 1000, for: "test")
        
        app.queues.schedule(ExportJob(filePath: outputPath)).at(Date().addingTimeInterval(scheduleJobDelay))
        try app.queues.startScheduledJobs()
        
        let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
        app.eventLoopGroup.next().scheduleTask(in: .seconds(csvExportDelaySeconds)) { () -> Void in
            let countFuture = Vote.query(on: app.db).all().map {
                $0.count
            }
            let _ = countFuture.flatMapThrowing { [weak self] voteCount in
                XCTAssertEqual(votes.count, voteCount, "Santiy check: Uh oh, these should be equal, check your DB")
                let fileContent = try String(contentsOf: URL(fileURLWithPath: self!.outputPath))
                let lines = fileContent.split(separator: "\n").count - ExportTests.HEADER_LENGTH
                XCTAssertEqual(lines, voteCount)
                promise.succeed(())
            }
        }
        
        try promise.futureResult.wait()
    }
    
    func testExportNoVotes() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        app.queues.schedule(ExportJob(filePath: outputPath)).at(Date().addingTimeInterval(scheduleJobDelay))
        try app.queues.startScheduledJobs()
        
        let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
        app.eventLoopGroup.next().scheduleTask(in: .seconds(csvExportDelaySeconds)) { () -> Void in
            let countFuture = Vote.query(on: app.db).all().map {
                $0.count
            }
            let _ = countFuture.flatMapThrowing { [weak self] voteCount in
                let fileContent = try String(contentsOf: URL(fileURLWithPath: self!.outputPath))
                let lines = fileContent.split(separator: "\n").count - ExportTests.HEADER_LENGTH
                XCTAssertEqual(lines, voteCount)
                promise.succeed(())
            }
        }
        
        try promise.futureResult.wait()
    }
    
    func testExportExistingFile() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let _ = createFile()
        let votes = try createVotes(on: app.db, for: "test")
        
        app.queues.schedule(ExportJob(filePath: outputPath)).at(Date().addingTimeInterval(scheduleJobDelay))
        try app.queues.startScheduledJobs()
        
        let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
        app.eventLoopGroup.next().scheduleTask(in: .seconds(csvExportDelaySeconds)) { () -> Void in
            let countFuture = Vote.query(on: app.db).all().map {
                $0.count
            }
            let _ = countFuture.flatMapThrowing { [weak self] voteCount in
                XCTAssertEqual(votes.count, voteCount, "Santiy check: Uh oh, these should be equal, check your DB")
                let fileContent = try String(contentsOf: URL(fileURLWithPath: self!.outputPath))
                let lines = fileContent.split(separator: "\n").count - ExportTests.HEADER_LENGTH
                XCTAssertEqual(lines, voteCount)
                promise.succeed(())
            }
        }
        
        try promise.futureResult.wait()
    }
    
    func testExportExistingFileWithData() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let votes = try createVotes(on: app.db, for: "test")
        
        app.queues.schedule(ExportJob(filePath: outputPath)).at(Date().addingTimeInterval(scheduleJobDelay))
        app.queues.schedule(ExportJob(filePath: outputPath)).at(Date().addingTimeInterval(scheduleJobDelay + scheduleJobDelay))
        try app.queues.startScheduledJobs()
        
        let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
        app.eventLoopGroup.next().scheduleTask(in: .seconds(csvExportDelaySeconds)) { () -> Void in
            let countFuture = Vote.query(on: app.db).all().map {
                $0.count
            }
            let _ = countFuture.flatMapThrowing { [weak self] voteCount in
                XCTAssertEqual(votes.count, voteCount, "Santiy check: Uh oh, these should be equal, check your DB")
                let fileContent = try String(contentsOf: URL(fileURLWithPath: self!.outputPath))
                let lines = fileContent.split(separator: "\n").count - ExportTests.HEADER_LENGTH
                XCTAssertEqual(lines, voteCount)
                promise.succeed(())
            }
        }
        
        try promise.futureResult.wait()
    }
}
