//
//  AuthenticationManager.swift
//  MemoPair
//
import LocalAuthentication

class AuthenticationManager {

    static let shared = AuthenticationManager()
    private init() {}

    // MARK: - Biometric

    func authenticateWithBiometrics(reason: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            let authError = mapLAError(error)
            completion(.failure(authError))
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evalError in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(self.mapLAError(evalError as NSError?)))
                }
            }
        }
    }

    // MARK: - Password

    func validatePassword(_ input: String) -> Bool {
        return input == KeychainManager.shared.getCurrentPassword()
    }

    // MARK: - Error mapping

    private func mapLAError(_ error: NSError?) -> AuthError {
        guard let error = error else { return .unknown }
        if let laError = error as? LAError {
            switch laError.code {
            case .userCancel:           return .userCancelled
            case .userFallback:         return .fallbackRequested
            case .biometryNotAvailable: return .biometryUnavailable
            case .biometryNotEnrolled:  return .biometryNotEnrolled
            case .biometryLockout:      return .biometryLockout
            case .passcodeNotSet:       return .passcodeNotSet
            default:                    return .failed(error.localizedDescription)
            }
        }
        return .failed(error.localizedDescription)
    }
}

// MARK: - AuthError

enum AuthError: Error {
    case userCancelled
    case fallbackRequested
    case biometryUnavailable
    case biometryNotEnrolled
    case biometryLockout
    case passcodeNotSet
    case failed(String)
    case unknown

    var message: String {
        switch self {
        case .userCancelled:        return ""
        case .fallbackRequested:    return "Use password instead."
        case .biometryUnavailable:  return "Biometric authentication is not available."
        case .biometryNotEnrolled:  return "No biometric authentication is enrolled."
        case .biometryLockout:      return "Biometric authentication is locked out."
        case .passcodeNotSet:       return "Passcode is not set on this device."
        case .failed(let msg):      return msg
        case .unknown:              return "Authentication failed."
        }
    }

    var requiresFallback: Bool {
        switch self {
        case .userCancelled: return false
        default: return true
        }
    }
}
