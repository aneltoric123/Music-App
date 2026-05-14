import SwiftUI
import Security
import LocalAuthentication
internal import Combine
import SwiftData

@MainActor
final class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isUnlocked = false
    @Published var currentUser: User?
    @Published var likedSongsPlaylist: Playlist?
    @AppStorage("username") var username: String = ""
    weak var audioManager:AudioPlayerManager?

    private let tokenKey = "music_app_token"
    private let context: ModelContext
    init(context:ModelContext) {
        self.context = context
        restoreSession()
    }

    func loadLikedSongs()  {
            guard let user = currentUser else { return }

            let descriptor = FetchDescriptor<Playlist>(
                predicate: #Predicate {
                    $0.name == "Liked Songs"
                }
            )

            likedSongsPlaylist =
                try? context.fetch(descriptor)
                    .first(where: { $0.owner?.id == user.id })
       
        }
    func login(username: String, password: String) {

            do {
                let users = try context.fetch(
                    FetchDescriptor<User>()
                )

                guard let user = users.first(
                    where: { $0.username == username }
                ) else {
                    print("User not found")
                    return
                }

                let valid = PasswordHasher.verify(
                    password: user.salt + password,
                    against: user.password
                )

                guard valid else {
                    print("Wrong password")
                    return
                }

                let token = UUID().uuidString
                saveToken(token)

                self.username = username
                self.currentUser = user
                loadLikedSongs()
                self.isLoggedIn = true
                authenticateWithFaceID()

            } catch {
                print("Login error:", error)
            }
        }

    func logout() {
        deleteToken()

        isLoggedIn = false
        isUnlocked = false
        username = ""
    }


    func restoreSession() {

        guard getToken() != nil else { return }

        do {
            let users = try context.fetch(
                FetchDescriptor<User>()
            )

            if let user = users.first(
                where: { $0.username == username }
            ) {

                currentUser = user
                loadLikedSongs()
                isLoggedIn = true

                authenticateWithFaceID()
            } else {
                logout()
            }

        } catch {
            print("Restore session failed:", error)
            logout()
        }
    }
  


    func authenticateWithFaceID() {

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) {

            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock your music"
            ) { success, _ in

                DispatchQueue.main.async {
                    self.isUnlocked = success
                }
            }

        } else {
            isUnlocked = true
        }
    }


    private func saveToken(_ token: String) {

        let data = Data(token.utf8)

        deleteToken()

        let query: [String:Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]

        SecItemAdd(query as CFDictionary,nil)
    }

    private func getToken() -> String? {

        let query: [String:Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?

        SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard let data = result as? Data else {
            return nil
        }

        return String(data:data, encoding:.utf8)
    }

    private func deleteToken() {

        let query: [String:Any] = [
            kSecClass as String:kSecClassGenericPassword,
            kSecAttrAccount as String:tokenKey
        ]

        SecItemDelete(query as CFDictionary)
    }
}
