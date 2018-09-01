// A Delegate with more advanced info on messages and connection etc.
public protocol WebSocketAdvancedDelegate: class {
    func websocketDidConnect(socket: StarscreamWebSocket)
    func websocketDidDisconnect(socket: StarscreamWebSocket, error: Error?)
    func websocketDidReceiveMessage(socket: StarscreamWebSocket, text: String, response: StarscreamWebSocket.WSResponse)
    func websocketDidReceiveData(socket: StarscreamWebSocket, data: Data, response: StarscreamWebSocket.WSResponse)
    func websocketHttpUpgrade(socket: StarscreamWebSocket, request: String)
    func websocketHttpUpgrade(socket: StarscreamWebSocket, response: String)
}

public protocol WSStream {
}

public class FoundationStream: WSStream {
    public init() {
    }
}

// wrapper around Vapor/Websocket into StarscreamWebSocket(https://github.com/daltoniam/Starscream)
public class StarscreamWebSocket {
    public class WSResponse { // Stub

    }

    public var advancedDelegate: WebSocketAdvancedDelegate?

    var path = ""
    var ws: WebSocket?
    var uuid: String?
    let worker = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    var futureWs: Future<WebSocket>?


    public var onText: ((String) -> Void)?
    public var onConnect: (() -> Void)?
    public var onDisconnect: ((Error?) -> Void)?
    public var onData: ((Data) -> Void)?
    var isConnected: Bool = false

    public init(request: URLRequest, protocols: [String]? = nil, stream: WSStream = FoundationStream()) {
        guard let url = request.url else {
            return
        }

        guard let host = url.host else {
            return
        }

        var origin = url.absoluteString

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

        self.ws?.onText { ws, text in
            self.onText?(text)
            self.advancedDelegate?.websocketDidReceiveMessage(socket: self, text: text, response: StarscreamWebSocket.WSResponse())
        }

        self.ws?.onCloseCode { code in
            self.onDisconnect?(nil)
            self.advancedDelegate?.websocketDidDisconnect(socket: self, error: nil)
        }

        self.ws?.onBinary({ ws, data in
            self.onData?(data)
            self.advancedDelegate?.websocketDidReceiveData(socket: self, data: data, response: StarscreamWebSocket.WSResponse())
        })

        self.ws?.onClose.always {
            self.isConnected = true
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
        }.catch { error in
            self.advancedDelegate?.websocketDidDisconnect(socket: self, error: error)
            self.onDisconnect?(error)
        }
    }

    public func close() {
        self.ws?.close(code: .normalClosure)
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

