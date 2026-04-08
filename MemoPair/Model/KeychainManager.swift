import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.avedevios.memopair"
    private let account = "parentPassword"
    
    private init() {}
    
    // MARK: - Password Management
    
    func savePassword(_ password: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: password.data(using: .utf8)!
        ]
        
        // Delete existing password first
        SecItemDelete(query as CFDictionary)
        
        // Add new password
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
    
    func deletePassword() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    func hasPassword() -> Bool {
        return getPassword() != nil
    }
    
    // MARK: - Default Password
    
    func getDefaultPassword() -> String {
        return "parent123"
    }
    
    func getCurrentPassword() -> String {
        return getPassword() ?? getDefaultPassword()
    }
}
