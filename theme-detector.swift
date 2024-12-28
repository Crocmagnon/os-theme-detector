import Foundation

func getSystemAppearance() -> String {
    let appleInterfaceStyle = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
    return appleInterfaceStyle
}

func runShellCommand(_ command: String, arguments: [String] = []) {
    let process = Process()

    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["fish", "-c", command] + arguments

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        print("Error running shell command: \(error)")
    }
}

func handleThemeChange() {
    let currentAppearance = getSystemAppearance()

    if currentAppearance == "Dark" {
        runShellCommand("dark")
    } else {
        runShellCommand("light")
    }
}

// Listen for theme changes
let notificationCenter = DistributedNotificationCenter.default
notificationCenter.addObserver(
    forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil,
    queue: nil) { _ in
        handleThemeChange()
    }

// Keep the script running to listen for changes
RunLoop.main.run()
