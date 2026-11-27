import Cocoa


class AboutPanelViewController: NSViewController {

    @IBOutlet weak var appTitle: NSTextField!
    @IBOutlet weak var appVersion: NSTextField!
    @IBOutlet var appAcknowledgments: NSTextView!
    @IBOutlet weak var appCopyright: NSTextField!
    @IBOutlet weak var appIcon: NSImageView!

    @IBOutlet weak var helpView: NSView!
    @IBOutlet weak var aboutView: NSView!

    @IBOutlet var helpBox: NSTextView!
    @IBOutlet weak var helpButton: NSButton!

    var isHelpVisible: Bool!
    var text: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        isHelpVisible = false
        self.forceHelp(force: true)

        let infoDict = Bundle.main.infoDictionary
        appTitle.stringValue = (infoDict!["CFBundleExecutable"] as? String)!
        appVersion.stringValue = "Version \((infoDict!["CFBundleShortVersionString"] as? String)!) (Build \((infoDict!["CFBundleVersion"] as? String)!))"
        appCopyright.stringValue = (infoDict!["NSHumanReadableCopyright"] as? String)!
        appIcon.image = NSApp.applicationIconImage

        // Set help
        if let helpURL = Bundle.main.url(forResource: "help", withExtension: "rtfd") {
            helpBox.textStorage?.append(
                try! NSAttributedString(
                    url: helpURL,
                    options: [.documentType: NSAttributedString.DocumentType.rtfd],
                    documentAttributes: nil
                )
            )
        }

        // Set acknowledgements
        if let ackURL = Bundle.main.path(forResource: "acknowledgments", ofType: "txt") {
            try! appAcknowledgments.string = String(contentsOfFile: ackURL, encoding: String.Encoding.utf8)
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.center()
        self.view.window?.level = .floating
    }

    func resizeWindow(size:(CGFloat,CGFloat)){
        self.view.window?.setFrame(NSRect(x:0,y:0,width:size.0,height:size.1), display: true)
    }

    @IBAction func toggleHelp(_ sender: Any?) {
        if self.isHelpVisible == true {
        // show about
            self.resizeWindow(size: (612, 312))
            self.isHelpVisible = false
            self.helpView.isHidden = true
            self.aboutView.isHidden = false
            self.helpButton.title = "Help"
        } else {
            // show help
            let screenSize = NSScreen.main!.frame
            let percent = CGFloat(0.80)
            self.resizeWindow(size: (612, screenSize.size.height * percent))
            self.view.window?.center()

            self.isHelpVisible = true
            self.helpView.isHidden = false
            self.aboutView.isHidden = true
            self.helpButton.title = "About"
        }
        self.view.window?.center()
    }

    @IBAction func visitWebsite(_ sender: Any?) {
        NSWorkspace.shared.open(NSURL(string: "https://github.com/justanotherkevin/BmoCal-menu-bar-calendar")! as URL)
    }

    func forceHelp(force: Bool) {
        if force == true {
            self.isHelpVisible = false
        } else {
            self.isHelpVisible = true
        }

        self.toggleHelp(nil)
    }

}

extension AboutPanelViewController {
    static func freshController() -> AboutPanelViewController {
        let storyboard = NSStoryboard(name: "AboutPanel", bundle: nil)
        let identifier = "AboutPanelViewController"

        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier)
            as? AboutPanelViewController else {
            fatalError("Why cant i find AboutPanelViewController? - Check AboutPanel.storyboard")
        }
        return viewcontroller
    }
}
