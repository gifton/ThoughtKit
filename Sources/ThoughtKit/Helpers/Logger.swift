//
//  File.swift
//  
//
//  Created by Gifton Okoronkwo on 12/22/24.
//

import Foundation

typealias Logger = ThoughtLogger
/// A logging utility for tracking application events and debugging information.
/// Each log level is associated with an emoji for better visual identification.
final class ThoughtLogger {
    // MARK: - Log Levels
    
    /// Defines the different levels of logging with associated emojis
    enum LogLevel: String {
        case debug = "🔍"    // Magnifying glass for detailed inspection
        case info = "ℹ️"     // Information symbol
        case warning = "⚠️"  // Warning symbol
        case error = "❌"    // Cross mark for errors
        
        /// Returns the text representation of the log level
        var description: String {
            switch self {
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warning: return "WARNING"
            case .error: return "ERROR"
            }
        }
    }
    
    // MARK: - Properties
    
    /// Shared instance for the logger
    static let shared = ThoughtLogger()
    
    /// Date formatter for timestamps
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Logging Methods
    
    /// Logs debug information
    /// - Parameters:
    ///   - message: The debug message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    /// Logs general information
    /// - Parameters:
    ///   - message: The info message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// Logs warning messages
    /// - Parameters:
    ///   - message: The warning message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// Logs error messages
    /// - Parameters:
    ///   - message: The error message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    
    /// Main logging function that handles the formatting and printing of log messages
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The logging level
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    private func log(
        _ message: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        // Extract the file name from the full path
        let fileName = (file as NSString).lastPathComponent
        // Remove the file extension
        let className = fileName.replacingOccurrences(of: ".swift", with: "")
        
        // Create timestamp
        let timestamp = dateFormatter.string(from: Date())
        
        // Format the log message
        let logMessage = """
        \(level.rawValue) [\(level.description)] [\(timestamp)]
        📱 Class: \(className)
        ⚙️ Function: \(function)
        📍 Line: \(line)
        📝 Message: \(message)
        ----------------------------------------
        """
        
        // Print to console
        print(logMessage)
    }
}

// MARK: - Convenience Extensions

extension ThoughtLogger {
    /// Logs an error with associated Error object
    /// - Parameters:
    ///   - error: The Error object to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    func error(
        _ error: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        self.error(error.localizedDescription, file: file, function: function, line: line)
    }
}

// Example Usage:
/*
class SampleClass {
    private let logger = ThoughtLogger.shared
    
    func someFunction() {
        logger.debug("This is a debug message")
        logger.info("This is an info message")
        logger.warning("This is a warning message")
        logger.error("This is an error message")
        
        do {
            throw NSError(domain: "SampleError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sample error occurred"])
        } catch {
            logger.error(error)
        }
    }
}

// Output Example:
🔍 [DEBUG] [2024-12-22 10:30:15.123]
📱 Class: SampleClass
⚙️ Function: someFunction()
📍 Line: 123
📝 Message: This is a debug message
----------------------------------------
*/
