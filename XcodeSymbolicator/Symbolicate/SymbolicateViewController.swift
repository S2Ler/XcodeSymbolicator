import AppKit
import SymbolicatorKit

@objc final class SymbolicateViewController: NSViewController {
    internal struct Input {
        let crashUrls: [URL]
        let dsymUrls: [URL]

        init(jsonCrashUrls: [URL],
             dsymUrls: [URL]) {
            self.crashUrls = jsonCrashUrls
            self.dsymUrls = dsymUrls
        }
    }

    @IBOutlet var consoleTextView: NSTextView!
    @IBOutlet weak var closeButton: NSButton!
    

    var input: Input?

    override func viewDidLoad() {
        super.viewDidLoad()
        consoleTextView.isEditable = false
        closeButton.isEnabled = false
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        DispatchQueue.global().async {
            self.runSymbolicataction()
            DispatchQueue.main.async {
                self.closeButton.isEnabled = true
            }
        }
    }

    private func runSymbolicataction() {
        guard let input = input else {
            return
        }

        for crashUrl in input.crashUrls {
            let outPath = crashUrl.deletingPathExtension().appendingPathExtension("desymbolicated.crash").path
            if FileManager.default.fileExists(atPath: outPath) {
                try? FileManager.default.removeItem(atPath: outPath)
            }
            do {
                try symbolicate(crashReportURL: crashUrl,
                                dsymUrls: input.dsymUrls,
                                outPath: outPath,
                                display: consoleTextView)
            }
            catch {
                consoleTextView.show("Finished with error: \(error)")
            }
        }
    }
}
