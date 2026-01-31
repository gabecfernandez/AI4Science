import Foundation

public extension Result {
    /// Get value if success, otherwise nil
    var value: Success? {
        guard case .success(let value) = self else { return nil }
        return value
    }

    /// Get error if failure, otherwise nil
    var error: Failure? {
        guard case .failure(let error) = self else { return nil }
        return error
    }

    /// Check if result is success
    var isSuccess: Bool {
        value != nil
    }

    /// Check if result is failure
    var isFailure: Bool {
        error != nil
    }

    /// Map success value
    func map<U>(_ transform: (Success) -> U) -> Result<U, Failure> {
        switch self {
        case .success(let value):
            .success(transform(value))
        case .failure(let error):
            .failure(error)
        }
    }

    /// Map failure error
    func mapError<E>(_ transform: (Failure) -> E) -> Result<Success, E> {
        switch self {
        case .success(let value):
            .success(value)
        case .failure(let error):
            .failure(transform(error))
        }
    }

    /// Flat map success value
    func flatMap<U>(_ transform: (Success) -> Result<U, Failure>) -> Result<U, Failure> {
        switch self {
        case .success(let value):
            transform(value)
        case .failure(let error):
            .failure(error)
        }
    }

    /// Get or else value
    func getOrElse(_ value: Success) -> Success {
        self.value ?? value
    }

    /// Get or else value from closure
    func getOrElse(_ transform: (Failure) -> Success) -> Success {
        guard case .failure(let error) = self else { return value! }
        return transform(error)
    }

    /// Execute closure if success
    @discardableResult
    func onSuccess(_ handler: (Success) -> Void) -> Result<Success, Failure> {
        if case .success(let value) = self {
            handler(value)
        }
        return self
    }

    /// Execute closure if failure
    @discardableResult
    func onFailure(_ handler: (Failure) -> Void) -> Result<Success, Failure> {
        if case .failure(let error) = self {
            handler(error)
        }
        return self
    }

    /// Recover from failure
    func recover(_ handler: (Failure) -> Result<Success, Failure>) -> Result<Success, Failure> {
        switch self {
        case .success:
            self
        case .failure(let error):
            handler(error)
        }
    }

    /// Get description
    var description: String {
        switch self {
        case .success(let value):
            "success(\(value))"
        case .failure(let error):
            "failure(\(error))"
        }
    }
}

public extension Result where Failure == Error {
    /// Create result from throwing operation
    init(catching operation: () throws -> Success) {
        do {
            self = .success(try operation())
        } catch {
            self = .failure(error)
        }
    }
}

public extension Result {
    /// Combine two results
    static func combine<U>(
        _ result1: Result<Success, Failure>,
        _ result2: Result<U, Failure>
    ) -> Result<(Success, U), Failure> {
        switch (result1, result2) {
        case let (.success(v1), .success(v2)):
            .success((v1, v2))
        case let (.failure(e), _):
            .failure(e)
        case let (_, .failure(e)):
            .failure(e)
        }
    }

    /// Combine three results
    static func combine<U, V>(
        _ result1: Result<Success, Failure>,
        _ result2: Result<U, Failure>,
        _ result3: Result<V, Failure>
    ) -> Result<(Success, U, V), Failure> {
        switch (result1, result2, result3) {
        case let (.success(v1), .success(v2), .success(v3)):
            .success((v1, v2, v3))
        case let (.failure(e), _, _):
            .failure(e)
        case let (_, .failure(e), _):
            .failure(e)
        case let (_, _, .failure(e)):
            .failure(e)
        }
    }
}
