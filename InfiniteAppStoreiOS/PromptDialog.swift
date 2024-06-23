import UIKit

extension UIApplication {
    private func prompt(title: String?, message: String?, showTextField: Bool, placeholder: String?, callback: @escaping (Bool, String?) -> Void) {
        guard let vc = viewControllerForModalPresentation else {
            callback(false, nil)
            return
        }
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if showTextField {
            dialog.addTextField { field in
                field.placeholder = placeholder
            }
        }
        dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            callback(false, nil)
        }))
        dialog.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
            let text = dialog.textFields?.first?.text
            callback(true, text)
        }))
        vc.present(dialog, animated: true, completion: nil)
    }

    func prompt(title: String?, message: String?, showTextField: Bool, placeholder: String?) async -> (ok: Bool, text: String?) {
        return await withCheckedContinuation { cont in
            Task {
                await MainActor.run {
                    self.prompt(title: title, message: message, showTextField: showTextField, placeholder: placeholder) { ok, text in
                        cont.resume(returning: (ok, text))
                    }
                }
            }
        }
    }

    func showAlert(_ alert: UIAlertController) {
        viewControllerForModalPresentation?.present(alert, animated: true, completion: nil)
    }
}

extension UIViewController {
    var topmostPresentedViewController: UIViewController {
        return presentedViewController?.topmostPresentedViewController ?? self
    }
}

private extension UIScene {
    var activityScore: Int {
        switch activationState {
        case .foregroundActive: return 3
        case .foregroundInactive: return 2
        case .background: return 1
        default: return 0
        }
    }
}

extension UIApplication {
    var activeWindowScene: UIWindowScene? {
        self
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .sorted { $0.activityScore > $1.activityScore }.first
    }
    var activeWindow: UIWindow? {
        guard let window = activeWindowScene?.keyWindow ?? activeWindowScene?.windows.last else {
                  return nil
              }
        return window
    }
    var viewControllerForModalPresentation: UIViewController? {
        return activeWindow?.rootViewController?.topmostPresentedViewController
    }
}
