import AppKit
import Foundation

func getSystemAppearance() -> String {
    let appleInterfaceStyle = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
    return appleInterfaceStyle
}

func log(_ message: String) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let timestamp = dateFormatter.string(from: Date())
    print("[\(timestamp)] \(message)")
}

func runShellCommand(shellPath: String, command: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: shellPath)
    process.arguments = ["-c", command]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    do {
        try process.run()
        process.waitUntilExit()

        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        if let outputString = String(data: output, encoding: .utf8) {
            log("Shell Output: \(outputString)")
        }
    } catch {
        log("Error running shell command: \(error)")
    }
}

// Parse command-line arguments
guard CommandLine.arguments.count == 4 else {
    log("Usage: themeChangeDetector <shellPath> <darkModeCommand> <lightModeCommand>")
    exit(1)
}

let shellPath = CommandLine.arguments[1]
let darkModeCommand = CommandLine.arguments[2]
let lightModeCommand = CommandLine.arguments[3]

func handleThemeChange() {
    let currentAppearance = getSystemAppearance()

    log("Appearance: \(currentAppearance)")

    if currentAppearance == "Dark" {
        runShellCommand(shellPath: shellPath, command: darkModeCommand)
    } else {
        runShellCommand(shellPath: shellPath, command: lightModeCommand)
    }
}

// Single instance mechanism using a file lock
let lockFilePath = "/tmp/os-theme-detector.lock"
let fileManager = FileManager.default

if fileManager.fileExists(atPath: lockFilePath) {
    log("Another instance is already running. Exiting.")
    exit(0)
}

// Create the lock file
do {
    try "".write(toFile: lockFilePath, atomically: true, encoding: .utf8)
} catch {
    log("Failed to create lock file. Exiting.")
    exit(1)
}

func removeFile() {
    try? fileManager.removeItem(atPath: lockFilePath)
}

// Ensure the lock file is deleted when the program exits normally
atexit {
    removeFile()
}

// As well as trap SIGINT and SIGTERM signals
let signalCallback: sig_t = { signal in
    removeFile()
    exit(signal)
}
signal(SIGINT, signalCallback)
signal(SIGTERM, signalCallback)

// Listen for theme changes
DistributedNotificationCenter.default.addObserver(
    forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil,
    queue: nil
) { _ in
    log("detected systeme theme change")
    handleThemeChange()
}

DistributedNotificationCenter.default.addObserver(
    forName: NSNotification.Name("com.apple.screenIsUnlocked"),
    object: nil,
    queue: nil
) { _ in
    log("detected session unlock")
    handleThemeChange()
}

// Observer for system wake
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification,
    object: nil,
    queue: nil
) { _ in
    log("detected system wake")
    handleThemeChange()
}

log("Initial system appearance: \(getSystemAppearance())")

// Keep the script running to listen for changes
RunLoop.main.run()
