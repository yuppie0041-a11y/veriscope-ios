import UIKit
import WebKit

class ViewController: UIViewController {

    // MARK: - 설정값
    private let appURL    = "https://veriscope.mindsafe365.co.kr/?source=ios"
    private let appHost   = "veriscope.mindsafe365.co.kr"
    private let uaSuffix  = "VeriscopeiOS/1.0"   // 웹에서 앱 안인지 알아보는 표시 (bootstrap.php 의 is_ios_app)
    private let brandBlue = UIColor(red: 11 / 255, green: 83 / 255, blue: 148 / 255, alpha: 1)

    // MARK: - UI
    private var webView: WKWebView!
    private var indicator: UIActivityIndicatorView!
    private var errorView: UIView!
    private var downloadURL: URL?

    // MARK: - 생명주기
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupWebView()
        setupIndicator()
        setupErrorView()
        loadApp()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    // MARK: - WebView 구성
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()                 // 로그인 쿠키 유지
        // 기본 사용자 에이전트(iPhone, Safari)를 그대로 두고 끝에 앱 표시만 붙입니다
        config.applicationNameForUserAgent = "Version/18.0 Mobile/15E148 Safari/604.1 " + uaSuffix

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic

        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(pullRefresh), for: .valueChanged)
        webView.scrollView.refreshControl = refresh
    }

    private func setupIndicator() {
        indicator = UIActivityIndicatorView(style: .large)
        indicator.color = brandBlue
        indicator.hidesWhenStopped = true
        view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupErrorView() {
        errorView = UIView()
        errorView.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.96, alpha: 1)
        errorView.isHidden = true
        view.addSubview(errorView)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        errorView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: errorView.centerYAnchor, constant: -30),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: errorView.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: errorView.trailingAnchor, constant: -32)
        ])

        let title = UILabel()
        title.text = "인터넷에 연결되어 있지 않습니다"
        title.font = .boldSystemFont(ofSize: 18)
        title.textColor = brandBlue
        stack.addArrangedSubview(title)

        let sub = UILabel()
        sub.text = "논문 검사는 서버에서 이루어지므로 인터넷 연결이 필요합니다.\n연결을 확인한 뒤 다시 시도해 주십시오."
        sub.font = .systemFont(ofSize: 14)
        sub.textColor = .darkGray
        sub.textAlignment = .center
        sub.numberOfLines = 0
        stack.addArrangedSubview(sub)

        let btn = UIButton(type: .system)
        btn.setTitle("다시 시도", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 16)
        btn.backgroundColor = brandBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 32, bottom: 12, right: 32)
        btn.addTarget(self, action: #selector(retryLoad), for: .touchUpInside)
        stack.addArrangedSubview(btn)
    }

    // MARK: - 로드
    private func loadApp() {
        guard let url = URL(string: appURL) else { return }
        errorView.isHidden = true
        indicator.startAnimating()
        webView.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20))
    }

    @objc private func pullRefresh(_ sender: UIRefreshControl) {
        if webView.url == nil { loadApp() } else { webView.reload() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { sender.endRefreshing() }
    }

    @objc private func retryLoad() { loadApp() }

    private func isOwnHost(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == appHost
    }

    private func showError() {
        errorView.isHidden = false
    }

    /// 내려받은 보고서·수정본을 공유 창으로 넘깁니다 ("파일에 저장", 메일, 카카오톡 등).
    private func share(_ fileURL: URL) {
        let sheet = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 40, width: 1, height: 1)
        present(sheet, animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension ViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        indicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        indicator.stopAnimating()
        errorView.isHidden = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        indicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        indicator.stopAnimating()
        let nsErr = error as NSError
        if nsErr.code == NSURLErrorCancelled { return }                       // 다른 주소로 넘어가며 취소된 것
        if nsErr.domain == "WebKitErrorDomain" && nsErr.code == 102 { return }  // 내려받기로 바뀐 요청
        showError()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow); return
        }
        // mailto: 등은 시스템에 맡깁니다
        if let scheme = url.scheme?.lowercased(), scheme != "http", scheme != "https", scheme != "about", scheme != "blob", scheme != "data" {
            UIApplication.shared.open(url)
            decisionHandler(.cancel); return
        }
        // 서비스 주소는 앱 안에서, 그 밖(DOI·학술 사이트 링크 등)은 사파리로
        if scheme(of: url) == "about" || isOwnHost(url) || navigationAction.targetFrame?.isMainFrame == false {
            decisionHandler(.allow); return
        }
        UIApplication.shared.open(url)
        decisionHandler(.cancel)
    }

    private func scheme(of url: URL) -> String { url.scheme?.lowercased() ?? "" }

    // 첨부 파일(보고서·수정본·원본)은 화면에 띄우지 않고 내려받습니다
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if let http = navigationResponse.response as? HTTPURLResponse,
           let disposition = http.value(forHTTPHeaderField: "Content-Disposition"),
           disposition.lowercased().hasPrefix("attachment") {
            decisionHandler(.download); return
        }
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .download)
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
}

// MARK: - WKDownloadDelegate
extension ViewController: WKDownloadDelegate {

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let name = suggestedFilename.isEmpty ? "veriscope-download" : suggestedFilename
        let dest = dir.appendingPathComponent(name)
        downloadURL = dest
        completionHandler(dest)
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let url = downloadURL else { return }
        downloadURL = nil
        indicator.stopAnimating()
        share(url)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        downloadURL = nil
        indicator.stopAnimating()
        let alert = UIAlertController(title: nil, message: "파일을 내려받지 못했습니다. 잠시 뒤 다시 시도해 주십시오.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - WKUIDelegate (alert / confirm / 새 창)
extension ViewController: WKUIDelegate {

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    // 문서·계정 삭제처럼 되돌릴 수 없는 동작의 확인 창 (data-confirm)
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    // target="_blank" 링크: 서비스 주소는 같은 화면에서, 바깥 주소는 사파리로
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            if isOwnHost(url) {
                webView.load(navigationAction.request)
            } else {
                UIApplication.shared.open(url)
            }
        }
        return nil
    }
}
