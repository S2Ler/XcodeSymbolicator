import AppKit

extension NSPasteboardItem {
    func fileURL ()->URL? {
        if let refURL = self.string(forType: .fileURL) {
            return URL (fileURLWithPath: refURL).standardized
        }
        return nil
    }
}

@objc internal final class FilesDragTextView: NSTextView {
    var fileUrls: [URL] = []

    func renderFileUrls() {
        self.string = fileUrls.map({ $0.lastPathComponent }).joined(separator: "\n")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {

    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pbItems = sender.draggingPasteboard.pasteboardItems else {
            return true
        }
        fileUrls = []

        for item in pbItems {
            guard  item.types.contains(.fileURL) else {
                continue
            }


            guard let url = item.fileURL() else {
                continue
            }

            fileUrls.append(url)
        }

        renderFileUrls()

        return true
    }
}
