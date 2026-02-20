import Foundation

enum ClientError: Error {
	case malformedURL(URLComponents)
	case unexpectedResponse(URLResponse)
	case requestFailed
	case invalidArguments
}
