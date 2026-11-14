import UIKit

final class CloudViewController: UIViewController, UITextFieldDelegate {
    private let address = UITextField()
    private let host = UITextField()
    private let token = UITextField()
    private let imageView = UIImageView()
    private let message = UILabel()
    private var sessionID: String?
    private var baseURL = ""
    private var apiToken = ""
    private var refreshTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.02, green: 0.035, blue: 0.06, alpha: 1)
        buildUI()
    }

    private func style(_ field: UITextField, placeholder: String) {
        field.borderStyle = .roundedRect
        field.backgroundColor = UIColor(white: 0.12, alpha: 1)
        field.textColor = .white
        field.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor.lightGray])
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
    }

    private func buildUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        let title = UILabel()
        title.text = "NOVA CLOUD CHROMIUM"
        title.textColor = UIColor(red: 0.1, green: 0.9, blue: 0.85, alpha: 1)
        title.font = .boldSystemFont(ofSize: 18)
        host.placeholder = "PC address, e.g. http://192.168.1.10:8765"
        token.placeholder = "Cloud API token"
        address.placeholder = "Website URL"
        style(host, placeholder: "PC address, e.g. http://192.168.1.10:8765")
        style(token, placeholder: "Cloud API token")
        style(address, placeholder: "Website URL")
        host.text = UserDefaults.standard.string(forKey: "nova.cloud.host")
        token.isSecureTextEntry = true
        address.text = "https://web.bale.ai/"
        let connect = UIButton(type: .system)
        connect.setTitle("CONNECT & OPEN", for: .normal)
        connect.setTitleColor(.black, for: .normal)
        connect.backgroundColor = UIColor(red: 0.1, green: 0.9, blue: 0.85, alpha: 1)
        connect.layer.cornerRadius = 8
        connect.addTarget(self, action: #selector(startCloud), for: .touchUpInside)
        let close = UIButton(type: .system)
        close.setTitle("CLOSE", for: .normal)
        close.setTitleColor(.white, for: .normal)
        close.addTarget(self, action: #selector(closeScreen), for: .touchUpInside)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.isUserInteractionEnabled = true
        imageView.layer.borderColor = UIColor.darkGray.cgColor
        imageView.layer.borderWidth = 1
        imageView.layer.cornerRadius = 6
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        imageView.addGestureRecognizer(tap)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        imageView.addGestureRecognizer(pan)
        message.textColor = .lightGray
        message.font = .systemFont(ofSize: 11)
        message.numberOfLines = 2
        [title, host, token, address, connect, close, imageView, message].forEach { stack.addArrangedSubview($0) }
        imageView.heightAnchor.constraint(equalToConstant: 390).isActive = true
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    @objc private func startCloud() {
        guard let hostText = host.text, let url = URL(string: hostText), ["http", "https"].contains(url.scheme ?? ""),
              let tokenText = token.text, tokenText.count >= 24 else {
            message.text = "Enter the PC server URL and a token of at least 24 characters."
            return
        }
        baseURL = hostText.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        apiToken = tokenText
        UserDefaults.standard.set(baseURL, forKey: "nova.cloud.host")
        guard let site = URL(string: address.text ?? "https://web.bale.ai/") else { return }
        request(path: "/v1/sessions", method: "POST", body: ["url": site.absoluteString, "viewport_width": 375, "viewport_height": 620]) { data in
            guard let data = data, let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let sid = obj["session_id"] as? String else {
                self.message.text = "Could not create Chromium session. Check PC server and token."
                return
            }
            self.sessionID = sid
            self.message.text = "Connected to remote Chromium."
            self.fetchScreenshot()
            self.refreshTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.refresh), userInfo: nil, repeats: true)
        }
    }

    private func request(path: String, method: String = "GET", body: [String: Any]? = nil, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: baseURL + path) else { completion(nil); return }
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 45)
        req.httpMethod = method
        req.setValue("Bearer " + apiToken, forHTTPHeaderField: "Authorization")
        if let body = body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        URLSession.shared.dataTask(with: req) { data, _, error in
            DispatchQueue.main.async { completion(error == nil ? data : nil) }
        }.resume()
    }

    @objc private func refresh() { fetchScreenshot() }
    private func fetchScreenshot() {
        guard let sid = sessionID else { return }
        guard let url = URL(string: baseURL + "/v1/sessions/" + sid + "/screenshot") else { return }
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        req.setValue("Bearer " + apiToken, forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async { self.imageView.image = image }
        }.resume()
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: imageView)
        let size = imageView.bounds.size
        guard size.width > 0, size.height > 0, let sid = sessionID else { return }
        request(path: "/v1/sessions/\(sid)/tap", method: "POST", body: ["x": point.x / size.width, "y": point.y / size.height]) { _ in self.fetchScreenshot() }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .ended, let sid = sessionID {
            let delta = gesture.translation(in: imageView)
            request(path: "/v1/sessions/\(sid)/scroll", method: "POST", body: ["delta_x": Int(-delta.x), "delta_y": Int(-delta.y)]) { _ in self.fetchScreenshot() }
        }
    }

    @objc private func closeScreen() {
        refreshTimer?.invalidate()
        if let sid = sessionID { request(path: "/v1/sessions/\(sid)", method: "DELETE") { _ in } }
        dismiss(animated: true)
    }

    deinit { refreshTimer?.invalidate() }
}
