import UIKit
import WebKit

public final class TyradsPrivacyPolicyViewController: UIViewController {
    var onAccepted: (() -> Void)?
    var onDeclined: (() -> Void)?

    private lazy var webView: WKWebView = {
        let wv = WKWebView()
        wv.translatesAutoresizingMaskIntoConstraints = false
        return wv
    }()

    private lazy var acceptButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Accept & Continue", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = Tyrads.instance.colorMain ?? TyradsSDKConfig.secondaryColor
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var declineButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Decline", for: .normal)
        btn.setTitleColor(.secondaryLabel, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(declineTapped), for: .touchUpInside)
        return btn
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Privacy Policy"

        view.addSubview(webView)
        view.addSubview(acceptButton)
        view.addSubview(declineButton)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: acceptButton.topAnchor, constant: -16),

            acceptButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            acceptButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            acceptButton.bottomAnchor.constraint(equalTo: declineButton.topAnchor, constant: -8),
            acceptButton.heightAnchor.constraint(equalToConstant: 50),

            declineButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            declineButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            declineButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            declineButton.heightAnchor.constraint(equalToConstant: 44),
        ])

        if let url = URL(string: TyradsSDKConfig.privacyPolicyURL) {
            webView.load(URLRequest(url: url))
        }
    }

    @objc private func acceptTapped() {
        let prefs = UserDefaults.standard
        prefs.set(true, forKey: "\(TyradsKeyNames.privacyAcceptedForUserId)\(Tyrads.instance.publisherUserID)")
        dismiss(animated: true)
        onAccepted?()
    }

    @objc private func declineTapped() {
        dismiss(animated: true)
        onDeclined?()
    }
}
