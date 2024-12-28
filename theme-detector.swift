import Foundation

func getSystemAppearance() -> String {
    let appleInterfaceStyle = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
    return appleInterfaceStyle
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
            print("Shell Output: \(outputString)")
        }
    } catch {
        print("Error running shell command: \(error)")
    }
}

// Parse command-line arguments
guard CommandLine.arguments.count == 4 else {
    print("Usage: themeChangeDetector <shellPath> <darkModeCommand> <lightModeCommand>")
    exit(1)
}

let shellPath = CommandLine.arguments[1]
let darkModeCommand = CommandLine.arguments[2]
let lightModeCommand = CommandLine.arguments[3]

func handleThemeChange() {
    let currentAppearance = getSystemAppearance()

    print("System appearance changed to: \(currentAppearance)")

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
    print("Another instance is already running. Exiting.")
    exit(0)
}

// Create the lock file
do {
    try "".write(toFile: lockFilePath, atomically: true, encoding: .utf8)
} catch {
    print("Failed to create lock file. Exiting.")
    exit(1)
}

// Ensure the lock file is deleted when the program exits normally
atexit {
    try? fileManager.removeItem(atPath: lockFilePath)
}

// As well as trap SIGINT and SIGTERM signals
let signalCallback: sig_t = { signal in
    try? fileManager.removeItem(atPath: lockFilePath)
    exit(signal)
}
signal(SIGINT, signalCallback)
signal(SIGTERM, signalCallback)

// Listen for theme changes
let notificationCenter = DistributedNotificationCenter.default
notificationCenter.addObserver(
    forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil,
    queue: nil) { _ in
        handleThemeChange()
    }

print("Initial system appearance: \(getSystemAppearance())")

// Keep the script running to listen for changes
RunLoop.main.run()
