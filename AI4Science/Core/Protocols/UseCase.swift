import Foundation

/// Base protocol for use cases with result type
public protocol UseCase<Request, Response>: Sendable {
    associatedtype Request: Sendable
    associatedtype Response: Sendable

    func execute(request: Request) async throws -> Response
}

/// Use case with no request parameter
public protocol NoParameterUseCase<Response>: Sendable {
    associatedtype Response: Sendable

    func execute() async throws -> Response
}

/// Use case with no response parameter
public protocol NoResultUseCase<Request>: Sendable {
    associatedtype Request: Sendable

    func execute(request: Request) async throws
}

/// Use case with neither request nor response
public protocol EmptyUseCase: Sendable {
    func execute() async throws
}

/// Observer protocol for use cases that emit multiple values
public protocol UseCaseObserver<Request, Response>: Sendable {
    associatedtype Request: Sendable
    associatedtype Response: Sendable

    func observe(request: Request) async -> AsyncThrowingSequence<Response, Error>
}
