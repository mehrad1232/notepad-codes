import UIKit
import WebKit

final class BrowserViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate {
    private let bar = UIView()
    private let address = UITextField()
    private let web = WKWebView(frame: .zero)
    private let status = UILabel()
    private let back = UIButton(type: .system)
    private let forward = UIButton(type: .system)
    private let reload = UIButton(type: .system)
    private let bookmarks = UIButton(type: .system)
    private let history = UIButton(type: .system)
    private let accent = UIColor(red: 0.1, green: 0.9, blue: 0.85, alpha: 1)
    private let storage = UserDefaults.standard
    private let bookmarksKey = "nova.bookmarks"
    private let historyKey = "nova.history"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.025, green: 0.04, blue: 0.07, alpha: 1)
        configureUI()
        configureWeb()
        address.text = "https://web.bale.ai/"
        loadAddress()
    }

    private func configureUI() {
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = UIColor(red: 0.04, green: 0.07, blue: 0.11, alpha: 1)
        view.addSubview(bar)
        address.translatesAutoresizingMaskIntoConstraints = false
        address.borderStyle = .roundedRect
        address.backgroundColor = UIColor(red: 0.08, green: 0.12, blue: 0.17, alpha: 1)
        address.textColor = .white
        address.tintColor = accent
        address.autocapitalizationType = .none
        address.autocorrectionType = .no
        address.keyboardType = .URL
        address.returnKeyType = .go
        address.delegate = self
        bar.addSubview(address)

        let controls = UIStackView()
        controls.translatesAutoresizingMaskIntoConstraints = false
        controls.axis = .horizontal
        controls.distribution = .fillEqually
        controls.spacing = 5
        let items: [(UIButton, String)] = [(back, "‹"), (forward, "›"), (reload, "↻"), (bookmarks, "★"), (history, "◷")]
        for (button, title) in items {
            button.setTitle(title, for: .normal)
            button.setTitleColor(accent, for: .normal)
            button.titleLabel?.font = .boldSystemFont(ofSize: 23)
            controls.addArrangedSubview(button)
        }
        bar.addSubview(controls)

        status.translatesAutoresizingMaskIntoConstraints = false
        status.textColor = accent
        status.font = .systemFont(ofSize: 10, weight: .medium)
        status.text = "NOVA • ON-DEVICE"
        bar.addSubview(status)

        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 104),
            address.topAnchor.constraint(equalTo: bar.topAnchor, constant: 8),
            address.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 10),
            address.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -10),
            address.heightAnchor.constraint(equalToConstant: 34),
            controls.topAnchor.constraint(equalTo: address.bottomAnchor, constant: 4),
            controls.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 8),
            controls.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -8),
            controls.heightAnchor.constraint(equalToConstant: 30),
            status.topAnchor.constraint(equalTo: controls.bottomAnchor, constant: 2),
            status.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 12)
        ])

        web.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(web)
        NSLayoutConstraint.activate([
            web.topAnchor.constraint(equalTo: bar.bottomAnchor),
            web.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            web.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            web.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        back.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        forward.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        reload.addTarget(self, action: #selector(reloadPage), for: .touchUpInside)
        bookmarks.addTarget(self, action: #selector(showBookmarks), for: .touchUpInside)
        history.addTarget(self, action: #selector(showHistory), for: .touchUpInside)
    }

    private func configureWeb() {
        web.navigationDelegate = self
        web.allowsBackForwardNavigationGestures = true
        web.scrollView.keyboardDismissMode = .onDrag
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 12_5_8 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1 Mobile/15E148 Safari/604.1"
    }

    private func normalizedURL(_ raw: String) -> URL? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        return URL(string: value.contains("://") ? value : "https://" + value)
    }

    private func loadAddress() {
        guard let url = normalizedURL(address.text ?? "") else {
            status.text = "NOVA • INVALID ADDRESS"
            return
        }
        address.resignFirstResponder()
        status.text = "NOVA • LOADING"
        web.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 45))
    }

    private func saveCurrentPage() {
        guard let url = web.url?.absoluteString else { return }
        var items = storage.stringArray(forKey: bookmarksKey) ?? []
        if !items.contains(url) { items.insert(url, at: 0) }
        storage.set(Array(items.prefix(100)), forKey: bookmarksKey)
        status.text = "NOVA • BOOKMARK SAVED"
    }

    private func openSavedList(title: String, key: String, source: UIButton) {
        let items = storage.stringArray(forKey: key) ?? []
        let alert = UIAlertController(title: title, message: items.isEmpty ? "No saved pages yet." : nil, preferredStyle: .actionSheet)
        for item in items.prefix(12) {
            let label = item.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
            alert.addAction(UIAlertAction(title: String(label.prefix(55)), style: .default) { _ in
                self.address.text = item
                self.loadAddress()
            })
        }
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = source
            popover.sourceRect = source.bounds
        }
        present(alert, animated: true)
    }

    @objc private func goBack() { if web.canGoBack { web.goBack() } }
    @objc private func goForward() { if web.canGoForward { web.goForward() } }
    @objc private func reloadPage() { web.reload() }

    @objc private func showBookmarks() {
        let alert = UIAlertController(title: "NOVA Bookmarks", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Save Current Page", style: .default) { _ in self.saveCurrentPage() })
        alert.addAction(UIAlertAction(title: "Open Saved Pages", style: .default) { _ in
            self.openSavedList(title: "Bookmarks", key: self.bookmarksKey, source: self.bookmarks)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = bookmarks
            popover.sourceRect = bookmarks.bounds
        }
        present(alert, animated: true)
    }

    @objc private func showHistory() {
        openSavedList(title: "Recent History", key: historyKey, source: history)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        loadAddress()
        return true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        address.text = webView.url?.absoluteString
        status.text = "NOVA • ON-DEVICE WEBKIT"
        if let url = webView.url?.absoluteString {
            var items = storage.stringArray(forKey: historyKey) ?? []
            items.removeAll { $0 == url }
            items.insert(url, at: 0)
            storage.set(Array(items.prefix(100)), forKey: historyKey)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        status.text = "NOVA • LOAD ERROR"
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        status.text = "NOVA • LOAD ERROR"
    }
}
