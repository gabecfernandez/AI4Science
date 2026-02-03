import Testing
import Foundation
@testable import AI4Science

@Suite("AuthenticationService Tests")
struct AuthenticationServiceTests {

    // MARK: - Nonce generation

    @Test("Nonce is 32 characters")
    func testNonceLength() {
        #expect(AuthenticationService.generateNonce().count == 32)
    }

    @Test("Two nonces differ")
    func testNonceUniqueness() {
        #expect(AuthenticationService.generateNonce() != AuthenticationService.generateNonce())
    }

    @Test("Nonce uses only URL-safe characters")
    func testNonceCharacterSet() {
        let allowed = CharacterSet(charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        let nonce = AuthenticationService.generateNonce()
        #expect(CharacterSet(charactersIn: nonce).isSubset(of: allowed))
    }

    @Test("sha256 produces 64-char hex string")
    func testSha256Length() {
        #expect(AuthenticationService.sha256("hello").count == 64)
    }

    @Test("sha256 is deterministic")
    func testSha256Deterministic() {
        #expect(AuthenticationService.sha256("test") == AuthenticationService.sha256("test"))
    }

    // MARK: - AuthError → AppError mapping

    @Test("invalidCredentials maps correctly")
    func testInvalidCredentialsMap() {
        #expect(AuthError.invalidCredentials.appError == .authenticationError(.invalidCredentials))
    }

    @Test("expiredToken maps correctly")
    func testExpiredTokenMap() {
        #expect(AuthError.expiredToken.appError == .authenticationError(.expiredToken))
    }

    @Test("refreshFailed maps correctly")
    func testRefreshFailedMap() {
        #expect(AuthError.refreshFailed.appError == .authenticationError(.refreshFailed))
    }

    @Test("invalidUserId includes raw ID in description")
    func testInvalidUserIdDescription() {
        let raw = "not-a-uuid"
        #expect(AuthError.invalidUserId(raw).errorDescription?.contains(raw) == true)
    }
}
