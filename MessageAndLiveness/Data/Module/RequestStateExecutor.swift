//
//  RequestStateExecutor.swift
//  MessageAndLiveness
//
//  Created by Arifin Firdaus on 07/01/26.
//

/// Executes an async operation and maps its result into a `RequestState`.
///
/// This helper centralizes error handling for repository calls by:
/// - Returning `.loaded` when the operation succeeds
/// - Wrapping `ErrorResponse` or any thrown error into `.error`
///
/// ### Before
/// ```swift
/// func deleteDrivingLicense() async -> RequestState<GeneralResponse<EmptyData>> {
///     do {
///         let response = try await remote.deleteDrivingLicense()
///         return .loaded(response)
///     } catch let error as ErrorResponse {
///         return .error(error)
///     } catch {
///         return .error(error)
///     }
/// }
/// ```
///
/// ### After
/// ```swift
/// func deleteDrivingLicense() async -> RequestState<GeneralResponse<EmptyData>> {
///     await execute { try await remote.deleteDrivingLicense() }
/// }
/// ```
///
/// - Parameter operation: An async throwing operation to execute.
/// - Returns: A `RequestState` representing the outcome of the operation.
func execute<T>(_ operation: () async throws -> T) async -> RequestState<T> {
	do {
		let result = try await operation()
		return .loaded(result)
	} catch let error as ErrorResponse {
		return .error(error)
	} catch {
		return .error(error)
	}
}
