import AppKit
import os.log

final class SymbolicateSetupViewController: NSViewController {
    @IBOutlet var crashReportsDragTextView: FilesDragTextView!
    @IBOutlet var dsymsDragTextView: FilesDragTextView!

    @IBAction func onSymbolicate(_ sender: NSButtonCell) {

    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard segue.identifier == "symbolicate" else {
            return
        }

        guard let symbolicateViewController = segue.destinationController as? SymbolicateViewController else {
            os_log("Invalid destination view controller")
            return
        }

        let input = SymbolicateViewController.Input(jsonCrashUrls: crashReportsDragTextView.fileUrls,
                                                    dsymUrls: dsymsDragTextView.fileUrls)
        symbolicateViewController.input = input
    }

    override func shouldPerformSegue(withIdentifier identifier: NSStoryboardSegue.Identifier, sender: Any?) -> Bool {
        guard identifier == "symbolicate" else {
            return false
        }

        var hasAtLeastOneValidCrashLogURL: Bool = false

        for log in crashReportsDragTextView.fileUrls {
            if FileManager.default.fileExists(atPath: log.path) {
                hasAtLeastOneValidCrashLogURL = true
                break
            }
        }

        var hasAtLeastOneValidDsymPath: Bool = false

        for dsym in dsymsDragTextView.fileUrls {
            if FileManager.default.fileExists(atPath: dsym.path) {
                hasAtLeastOneValidDsymPath = true
                break
            }

        }

        return hasAtLeastOneValidCrashLogURL && hasAtLeastOneValidDsymPath
    }

}

