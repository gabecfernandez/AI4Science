//
//  UserTests.swift
//  AI4ScienceTests
//
//  Created for AI4Science UTSA
//

import Testing
import Foundation
@testable import AI4Science

@Suite("User Model Tests")
struct UserTests {

    // MARK: - Initialization Tests

    @Test("User initializes with all required properties")
    func testUserInitialization() {
        let user = User(
            id: UUID(),
            email: "researcher@utsa.edu",
            displayName: "Dr. Jane Smith",
            role: .researcher,
            labAffiliation: LabAffiliation(
                id: UUID(),
                name: "Vision & AI Lab",
                institution: "UT San Antonio",
                department: "Computer Science"
            )
        )

        #expect(user.email == "researcher@utsa.edu")
        #expect(user.displayName == "Dr. Jane Smith")
        #expect(user.role == .researcher)
        #expect(user.labAffiliation?.name == "Vision & AI Lab")
    }

    @Test("User role enum has correct cases")
    func testUserRoles() {
        let roles: [UserRole] = [.citizen, .researcher, .labManager, .admin]
        #expect(roles.count == 4)
    }

    @Test("Citizen user has no lab affiliation required")
    func testCitizenUser() {
        let citizen = User(
            id: UUID(),
            email: "citizen@gmail.com",
            displayName: "John Doe",
            role: .citizen,
            labAffiliation: nil
        )

        #expect(citizen.role == .citizen)
        #expect(citizen.labAffiliation == nil)
    }

    // MARK: - Codable Tests

    @Test("User encodes and decodes correctly")
    func testUserCodable() throws {
        let originalUser = User(
            id: UUID(),
            email: "test@utsa.edu",
            displayName: "Test User",
            role: .researcher,
            labAffiliation: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalUser)

        let decoder = JSONDecoder()
        let decodedUser = try decoder.decode(User.self, from: data)

        #expect(decodedUser.id == originalUser.id)
        #expect(decodedUser.email == originalUser.email)
        #expect(decodedUser.role == originalUser.role)
    }

    // MARK: - Validation Tests

    @Test("User email validation")
    func testEmailValidation() {
        let validEmails = ["test@utsa.edu", "user.name@domain.com", "a@b.co"]
        let invalidEmails = ["notanemail", "@nodomain.com", "no@", ""]

        for email in validEmails {
            #expect(email.isValidEmail == true, "Expected \(email) to be valid")
        }

        for email in invalidEmails {
            #expect(email.isValidEmail == false, "Expected \(email) to be invalid")
        }
    }

    // MARK: - Equatable Tests

    @Test("Users with same ID are equal")
    func testUserEquality() {
        let id = UUID()
        let user1 = User(id: id, email: "a@b.com", displayName: "A", role: .citizen, labAffiliation: nil)
        let user2 = User(id: id, email: "a@b.com", displayName: "A", role: .citizen, labAffiliation: nil)

        #expect(user1 == user2)
    }

    // MARK: - Sendable Compliance

    @Test("User is Sendable")
    func testUserSendable() async {
        let user = User(
            id: UUID(),
            email: "test@utsa.edu",
            displayName: "Test",
            role: .citizen,
            labAffiliation: nil
        )

        // Test that user can be passed across actor boundaries
        let result = await Task.detached {
            return user.email
        }.value

        #expect(result == "test@utsa.edu")
    }
}

// MARK: - Lab Affiliation Tests

@Suite("Lab Affiliation Tests")
struct LabAffiliationTests {

    @Test("Lab affiliation initializes correctly")
    func testLabAffiliationInit() {
        let lab = LabAffiliation(
            id: UUID(),
            name: "Fernandez Lab",
            institution: "UTSA",
            department: "Computer Science"
        )

        #expect(lab.name == "Fernandez Lab")
        #expect(lab.institution == "UTSA")
    }

    @Test("Lab affiliation full name formatting")
    func testLabFullName() {
        let lab = LabAffiliation(
            id: UUID(),
            name: "Vision & AI Lab",
            institution: "UT San Antonio",
            department: "Computer Science"
        )

        let expectedFullName = "Vision & AI Lab - Computer Science, UT San Antonio"
        #expect(lab.fullName == expectedFullName)
    }
}
