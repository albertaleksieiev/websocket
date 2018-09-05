// A Delegate with more advanced info on messages and connection etc.
public protocol WebSocketAdvancedDelegate: class {
    func websocketDidConnect(socket: StarscreamWebSocket)
    func websocketDidDisconnect(socket: StarscreamWebSocket, error: Error?)
    func websocketDidReceiveMessage(socket: StarscreamWebSocket, text: String, response: StarscreamWebSocket.WSResponse)
    func websocketDidReceiveData(socket: StarscreamWebSocket, data: Data, response: StarscreamWebSocket.WSResponse)
    func websocketHttpUpgrade(socket: StarscreamWebSocket, request: String)
    func websocketHttpUpgrade(socket: StarscreamWebSocket, response: String)
}
public enum CloseCode : UInt16 {
    case normal                 = 1000
    case goingAway              = 1001
    case protocolError          = 1002
    case protocolUnhandledType  = 1003
    // 1004 reserved.
    case noStatusReceived       = 1005
    //1006 reserved.
    case encoding               = 1007
    case policyViolated         = 1008
    case messageTooBig          = 1009
}
public protocol WSStream {
}

public class FoundationStream: WSStream {
    public init() {
    }
}

// wrapper around Vapor/Websocket into StarscreamWebSocket(https://github.com/daltoniam/Starscream)
open class StarscreamWebSocket: NSObject {
    public class WSResponse { // Stub

    }

    public var advancedDelegate: WebSocketAdvancedDelegate?

    var ws: WebSocket?
    var uuid: String?
    let worker = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    var futureWs: Future<WebSocket>?


    public var onText: ((String) -> Void)?
    public var onConnect: (() -> Void)?
    public var onDisconnect: ((Error?) -> Void)?
    public var onData: ((Data) -> Void)?
    public var isConnected: Bool = false
    public let request: URLRequest

    public init(request: URLRequest, protocols: [String]? = nil, stream: WSStream = FoundationStream()) {
        self.request = request

        guard let url = request.url else {
            return
        }

        guard let host = url.host else {
            return
        }

        var origin = url.absoluteString
        var path = ""

        if let hostUrl = URL(string: "/", relativeTo: url) {
            origin = hostUrl.absoluteString
            let indx = origin.index(before: origin.endIndex)

            origin.remove(at: indx)
            path = String(url.absoluteString.suffix(from: indx))
        } else {
            return
        }

        var headers = HTTPHeaders()
        if let authKey = request.value(forHTTPHeaderField: "Authorization") {
            headers = HTTPHeaders(dictionaryLiteral: (("Authorization", authKey)))
        }

        let scheme: HTTPScheme = url.absoluteString.hasPrefix("wss") ? .wss : .ws

        futureWs = HTTPClient.webSocket(
                scheme: scheme,
                hostname: host,
                path: path,
                headers: headers,
                maxFrameSize: 1 << 21,
                on: worker
        )
    }

    private func connected(_ ws: WebSocket) {
        self.ws = ws
        self.isConnected = true

        var response = "HTTP/1.1 101 Switching Protocols\r\n"
        if let upgradeResponse = ws.upgradeResponse {
            response += upgradeResponse
                    .headers
                    .map {"\($0.name): \($0.value)"}
                    .joined(separator: "\r\n")
        }
        self.advancedDelegate?.websocketHttpUpgrade(socket: self, response: response)
        
        self.ws?.onText { ws, text in
            self.onText?(text)
            self.advancedDelegate?.websocketDidReceiveMessage(socket: self, text: text, response: StarscreamWebSocket.WSResponse())
        }

        self.ws?.onCloseCode { code in
            self.onDisconnect?(nil)
            self.advancedDelegate?.websocketDidDisconnect(socket: self, error: nil)
            self.isConnected = false
        }

        self.ws?.onBinary({ ws, data in
            self.onData?(data)
            self.advancedDelegate?.websocketDidReceiveData(socket: self, data: data, response: StarscreamWebSocket.WSResponse())
        })

        self.ws?.onClose.always {
            self.isConnected = false
        }

        self.advancedDelegate?.websocketDidConnect(socket: self)
        self.onConnect?()
    }


    public func write(string: String) {
        self.ws?.send(string)
    }

    public func write(data: Data) {
        self.ws?.send(data)
    }

    public func connect() {
        _ = self.futureWs?.do { ws in
            self.connected(ws)
            self.isConnected = true
        }.catch { error in
            self.advancedDelegate?.websocketDidDisconnect(socket: self, error: error)
            self.onDisconnect?(error)
        }
    }

    public func disconnect() {
        self.ws?.close(code: .normalClosure)
    }

    public func disconnect(_ code: CloseCode) {
        self.ws?.close(code: WebSocketErrorCode(codeNumber: Int(code.rawValue)))
    }

    public func write(string: String, completion: (() -> ())?) {
        guard let completionCallback = completion else {
            self.write(string: string)
            return
        }

        let promise = worker.eventLoop.newPromise(Void.self)
        self.ws?.send(string, promise: promise)
        _ = promise.futureResult.do {
            completionCallback()
        }
    }
}

