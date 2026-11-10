import os

/// Logger central. Los mensajes dinámicos van como `.private` (se redactan fuera de un depurador).
/// `debug` no emite nada en Release; `info`/`error` sí, así que no pases datos personales en ellos.
enum AppLog {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.llego", category: "App")

    static func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        logger.debug("\(message(), privacy: .private)")
        #endif
    }

    static func info(_ message: @autoclosure () -> String) {
        logger.info("\(message(), privacy: .private)")
    }

    static func error(_ message: @autoclosure () -> String) {
        logger.error("\(message(), privacy: .private)")
    }
}
