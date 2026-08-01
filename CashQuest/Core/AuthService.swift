import Foundation
import FirebaseAuth

@MainActor
final class AuthService: ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String?
    @Published var isBusy = false

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.user = user }
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    func signUp(email: String, password: String, name: String) async {
        isBusy = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let change = result.user.createProfileChangeRequest()
            change.displayName = name.isEmpty ? "Player" : name
            try? await change.commitChanges()
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }

    func signIn(email: String, password: String) async {
        isBusy = true
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    /// Note : Firebase exige parfois une reconnexion récente avant la suppression.
    func deleteAccount() async {
        do {
            try await Auth.auth().currentUser?.delete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
