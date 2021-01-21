import Foundation
import os.log

public enum Error: Swift.Error {
    case emptyOutPath
    case commandError(commandName: String, statusCode: Int32, output: String)
}

public func symbolicate(crashReportURL: URL,
                          dsymUrls: [URL],
                          outPath: String,
                          display: Display) throws {
    let tmpFileString = crashReportURL.path

    display.show("Searching for symbolicator")
    let symbolicatecrashPath: String
    if let cachedSymbolicatorPath = cachedSymbolicatorPath {
        symbolicatecrashPath = cachedSymbolicatorPath
    }
    else {
        symbolicatecrashPath = try findSymbolicaterPath()
    }
    cachedSymbolicatorPath = symbolicatecrashPath

    display.show("Symbolicator found at path: \(symbolicatecrashPath)")

    var symbolicationArguments: [String] = []
    for dsymUrl in dsymUrls {
        symbolicationArguments.append(contentsOf: ["-d", dsymUrl.path])
    }

    guard !outPath.isEmpty else {
        throw Error.emptyOutPath
    }

    symbolicationArguments.append("-o")
    symbolicationArguments.append(outPath)

    symbolicationArguments.append(tmpFileString)

    display.show("Running symbolication\nlaunchPath: \(symbolicatecrashPath)\nparams:\(symbolicationArguments)")

    let (output, statusCode) = shell(launchPath: symbolicatecrashPath,
                                     arguments: symbolicationArguments,
                                     environment: ["DEVELOPER_DIR": developerDir().path])
    if (statusCode == 0) {
        if !output.isEmpty {
            display.show("Symbolicated succesfully with output: \n\(output)")
        }
        else {
            display.show("Symbolicated succesfully")
        }
    }
    else {
        throw Error.commandError(commandName: "symbolicatecrash", statusCode: statusCode, output: output)
    }
}

private func developerDir() -> URL {
    let (output, _) = shell(launchPath: "/usr/bin/xcode-select",
                            arguments: ["-p"],
                            environment: nil)
    return URL(fileURLWithPath: output.trimmingCharacters(in: .whitespacesAndNewlines))
}

private func xcodeSharedFrameworksDir() -> URL {
    var developerDir = SymbolicatorKit.developerDir()
    developerDir.deleteLastPathComponent()
    return developerDir.appendingPathComponent("SharedFrameworks")
}

// MARK: - Find symbolicatecrash app

private var cachedSymbolicatorPath: String?

private func findSymbolicaterPath() throws -> String {
    let (output, statusCode) = shell(launchPath: "/usr/bin/find",
                                     arguments: [xcodeSharedFrameworksDir().path, "-name", "symbolicatecrash"])
    guard statusCode == 0 else {
        throw Error.commandError(commandName: "find symbolicatecrash", statusCode: statusCode, output: output)
    }

    if let path = output
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .components(separatedBy: "\n")
        .last {
        return path
    }
    else {
        throw Error.commandError(commandName: "find symbolicatecrash", statusCode: -1, output: "")
    }
}
