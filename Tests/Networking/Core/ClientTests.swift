//
//  ClientTests.swift
//  PAYJPTests
//
//  Created by Tadashi Wakayanagi on 2019/12/02.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import XCTest
import OHHTTPStubs
@testable import PAYJP

struct MockRequest: BaseRequest {
    typealias Response = Token

    var path: String
    var httpMethod: String = "GET"

    let tokenId: String

    init(tokenId: String, path: String? = nil) {
        self.tokenId = tokenId
        self.path = path ?? "mocks/\(tokenId)"
    }
}

class ClientTests: XCTestCase {

    let client = Client.shared

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testRequest_systemError() {
        let notConnectedError = NSError(domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue)
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/mocks") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            return HTTPStubsResponse(error: notConnectedError)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        let request = MockRequest(tokenId: "mock_id")
        client.request(with: request) { result in
            switch result {
            case .failure(let apiError):
                switch apiError {
                case .systemError:
                    expectation.fulfill()
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequest_invalidJSON_200() {
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/mocks") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        let request = MockRequest(tokenId: "mock_id")
        client.request(with: request) { result in
            switch result {
            case .failure(let apiError):
                switch apiError {
                case .invalidJSON:
                    expectation.fulfill()
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequest_invalidJSON_500() {
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/mocks") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        let request = MockRequest(tokenId: "mock_id")
        client.request(with: request) { result in
            switch result {
            case .failure(let apiError):
                switch apiError {
                case .invalidJSON:
                    expectation.fulfill()
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequest_serviceError() {
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/mocks") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            let data = TestFixture.JSON(by: "error.json")
            return HTTPStubsResponse(data: data, statusCode: 400, headers: nil)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        let request = MockRequest(tokenId: "mock_id")
        client.request(with: request) { result in
            switch result {
            case .failure(let apiError):
                switch apiError {
                case .serviceError:
                    expectation.fulfill()
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequest_rateLimitError() {
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/mocks") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            let data = TestFixture.JSON(by: "error.json")
            return HTTPStubsResponse(data: data, statusCode: 429, headers: nil)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        let request = MockRequest(tokenId: "mock_id")
        client.request(with: request) { result in
            switch result {
            case .failure(let apiError):
                switch apiError {
                case .rateLimitExceeded:
                    expectation.fulfill()
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequest_success() {
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/mocks") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            let data = TestFixture.JSON(by: "token.json")
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        let request = MockRequest(tokenId: "mock_id")
        client.request(with: request) { result in
            switch result {
            case .success:
                expectation.fulfill()
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequest_requiredTds() {
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/tokens") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            let data = "{\"object\": \"three_d_secure_token\", \"id\": \"tds_xxx\"}".data(using: .utf8)!
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        var request = MockRequest(tokenId: "mock_id")
        request.path = "tokens"
        request.httpMethod = "POST"
        client.request(with: request) { result in
            switch result {
            case .failure(let apiError):
                switch apiError {
                case .requiredThreeDSecure:
                    expectation.fulfill()
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequest_requiredTds_token_nil() {
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/tokens") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        var request = MockRequest(tokenId: "mock_id")
        request.path = "tokens"
        request.httpMethod = "GET"
        client.request(with: request) { result in
            switch result {
            case .failure(let apiError):
                switch apiError {
                case .invalidJSON:
                    expectation.fulfill()
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateThreeDSecureToken() {
        let data = "{\"object\": \"three_d_secure_token\", \"id\": \"tds_xxx\"}".data(using: .utf8)!
        var request = MockRequest(tokenId: "mock_id")
        request.httpMethod = "POST"
        let response = mock200Response()

        let tdsToken = client.createThreeDSecureToken(data: data, request: request, response: response)
        XCTAssertEqual(tdsToken?.identifier, "tds_xxx")
    }

    func testCreateThreeDSecureToken_otherObject() {
        let data = "{\"object\": \"token\", \"id\": \"tds_xxx\"}".data(using: .utf8)!
        var request = MockRequest(tokenId: "mock_id")
        request.httpMethod = "POST"
        let response = mock200Response()

        let tdsToken = client.createThreeDSecureToken(data: data, request: request, response: response)
        XCTAssertNil(tdsToken)
    }

    func testCreateThreeDSecureToken_notHasId() {
        let data = "{\"object\": \"three_d_secure_token\"}".data(using: .utf8)!
        var request = MockRequest(tokenId: "mock_id")
        request.httpMethod = "POST"
        let response = mock200Response()

        let tdsToken = client.createThreeDSecureToken(data: data, request: request, response: response)
        XCTAssertNil(tdsToken)
    }

    func testCreateThreeDSecureToken_otherPath() {
        let data = "{\"object\": \"three_d_secure_token\", \"id\": \"tds_xxx\"}".data(using: .utf8)!
        var request = MockRequest(tokenId: "mock_id")
        request.httpMethod = "POST"
        let response = mock200Response(urlString: "\(PAYJPApiEndpoint)tokens/any")

        let tdsToken = client.createThreeDSecureToken(data: data, request: request, response: response)
        XCTAssertNil(tdsToken)
    }

    func testCreateThreeDSecureToken_notPost() {
        let data = "{\"object\": \"three_d_secure_token\", \"id\": \"tds_xxx\"}".data(using: .utf8)!
        var request = MockRequest(tokenId: "mock_id")
        request.httpMethod = "GET"
        let response = mock200Response()

        let tdsToken = client.createThreeDSecureToken(data: data, request: request, response: response)
        XCTAssertNil(tdsToken)
    }

    private func mock200Response(urlString: String = "\(PAYJPApiEndpoint)tokens") -> HTTPURLResponse {
        return HTTPURLResponse(url: URL(string: urlString)!,
                               statusCode: 200,
                               httpVersion: "",
                               headerFields: nil)!
    }
}
