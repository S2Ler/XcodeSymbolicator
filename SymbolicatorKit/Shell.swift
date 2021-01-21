import Foundation

func shell(launchPath: String,
           arguments: [String] = [],
           environment: [String : String]? = nil) -> (String , Int32) {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = arguments
    if let environment = environment {
        task.environment = environment
    }

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    task.waitUntilExit()
    return (output, task.terminationStatus)
}
