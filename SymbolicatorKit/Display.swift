import AppKit

public protocol Display {
    func show(_ string: String)
}

internal final class ConsoleDisplay: Display {
    func show(_ string: String) {
        print(string)
    }
}

extension NSTextView: Display {
    public func show(_ string: String) {
        if Thread.isMainThread {
            let s = NSAttributedString(string: "\(string)\n",
                attributes: [NSAttributedString.Key.foregroundColor : NSColor.textColor])
            textStorage?.append(s)
        } else {
            DispatchQueue.main.sync {
                self.show(string)
            }
        }
    }
}
