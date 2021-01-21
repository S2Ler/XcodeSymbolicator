import Foundation
import os.log

enum Error: Swift.Error {
    case emptyOutPath
    case unsupportedCrashExtension
    case cannotCreateKSCrashFilter
    case ksCrashError(Swift.Error?)
    case reportIsNotString
    case commandError(commandName: String, statusCode: Int32, output: String)
}

var cachedSymbolicatorPath: String?

internal func symbolicate(crashReportURL: URL,
                          dsymUrls: [URL],
                          outPath: String,
                          display: Display) throws {
    let jsonCrashReportData = try Data(contentsOf: crashReportURL)
    let tmpFileString: String

    if crashReportURL.pathExtension == "log" {
        tmpFileString = (NSTemporaryDirectory() as NSString).appendingPathComponent("tmp.crash")

        display.show("Converting json crash to Apple format")
        let jsonCrashReport = try JSONSerialization.jsonObject(with: jsonCrashReportData, options: [])


        guard let filter = KSCrashReportFilterAppleFmt(reportStyle: KSAppleReportStyleSymbolicatedSideBySide) else {
            throw Error.cannotCreateKSCrashFilter
        }

        let reportsFiltered = DispatchSemaphore(value: 0)

        var reports: [Any]? = nil
        var completed: Bool = false
        var error: Swift.Error? = nil

        filter.filterReports([jsonCrashReport], onCompletion: { (_reports, _completed, _error) in
            reports = _reports
            completed = _completed
            error = _error
            reportsFiltered.signal()
        })

        reportsFiltered.wait()

        guard completed else {
            throw Error.ksCrashError(error)
        }

        guard let reportString = reports?.first as? String else {
            throw Error.reportIsNotString
        }

        try reportString.write(toFile: tmpFileString, atomically: true, encoding: .utf8)
    }
    else if crashReportURL.pathExtension == "crash" {
        tmpFileString = crashReportURL.path
    }
    else {
        display.show("Error: Only .log and .crash reports are supported")
        throw Error.unsupportedCrashExtension
    }

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
                                     environment: ["DEVELOPER_DIR": "/Applications/Xcode.app/Contents/Developer"])
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

func findSymbolicaterPath() throws -> String {
    let (output, statusCode) = shell(launchPath: "/usr/bin/find",
                                     arguments: ["/Applications/Xcode.app", "-name", "symbolicatecrash"])
    guard statusCode == 0 else {
        throw Error.commandError(commandName: "find symbolicatecrash", statusCode: statusCode, output: output)
    }

    if let path = output.components(separatedBy: "\n").dropLast().last {
        return path
    }
    else {
        throw Error.commandError(commandName: "find symbolicatecrash", statusCode: -1, output: "")
    }
}
