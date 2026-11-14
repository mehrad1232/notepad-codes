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
    private let cloud = UIButton(type: .system)

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
        address.tintColor = UIColor(red: 0.1, green: 0.9, blue: 0.85, alpha: 1)
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
        controls.spacing = 8
        for (button, title) in [(back, "‹"), (forward, "›"), (reload, "↻"), (cloud, "CLOUD")] {
            button.setTitle(title, for: .normal)
            button.setTitleColor(UIColor(red: 0.1, green: 0.9, blue: 0.85, alpha: 1), for: .normal)
            button.titleLabel?.font = .boldSystemFont(ofSize: title == "CLOUD" ? 11 : 25)
            controls.addArrangedSubview(button)
        }
        bar.addSubview(controls)
        status.translatesAutoresizingMaskIntoConstraints = false
        status.textColor = UIColor(red: 0.2, green: 0.85, blue: 0.8, alpha: 1)
        status.font = .systemFont(ofSize: 10, weight: .medium)
        status.text = "NOVA • LOCAL WEBKIT"
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
            controls.topAnchor.constraint(equalTo: address.bottomAnchor, constant: 5),
            controls.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 10),
            controls.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -10),
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
        cloud.addTarget(self, action: #selector(openCloud), for: .touchUpInside)
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
        let candidate = value.contains("://") ? value : "https://" + value
        return URL(string: candidate)
    }

    private func loadAddress() {
        guard let url = normalizedURL(address.text ?? "") else { return }
        address.resignFirstResponder()
        status.text = "NOVA • LOADING"
        web.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 45))
    }

    @objc private func goBack() { if web.canGoBack { web.goBack() } }
    @objc private func goForward() { if web.canGoForward { web.goForward() } }
    @objc private func reloadPage() { web.reload() }
    @objc private func openCloud() {
        let controller = CloudViewController()
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { loadAddress(); return true }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        address.text = webView.url?.absoluteString
        status.text = "NOVA • LOCAL WEBKIT"
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        status.text = "NOVA • LOAD ERROR"
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        status.text = "NOVA • LOAD ERROR"
    }
}
