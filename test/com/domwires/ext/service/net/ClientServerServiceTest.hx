package com.domwires.ext.service.net;

import com.domwires.ext.service.net.server.socket.impl.NodeWebSocketServerService;
import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import com.domwires.ext.service.net.client.impl.NodeNetClientService;
import com.domwires.ext.service.net.client.impl.WebSocketClientService;
import com.domwires.ext.service.net.client.INetClientService;
import com.domwires.ext.service.net.client.NetClientServiceMessageType;
import com.domwires.ext.service.net.client.RequestType;
import com.domwires.ext.service.net.server.http.IHttpServerService;
import com.domwires.ext.service.net.server.http.impl.NodeHttpServerService;
import com.domwires.ext.service.net.server.NetServerServiceMessageType;
import com.domwires.ext.service.net.server.socket.impl.NodeSocketServerService;
import com.domwires.ext.service.net.server.socket.impl.WebSocketServerService;
import com.domwires.ext.service.net.server.socket.ISocketServerService;
import com.domwires.ext.service.net.server.socket.SocketServerServiceMessageType;
import utest.Assert;
import utest.Async;
import utest.Test;

class ClientServerTest_NodeHttp_NodeSocket_NodeClient extends ClientServerServiceTest
{
    public function new()
    {
        super(NodeHttpServerService, NodeSocketServerService, NodeNetClientService);
    }
}

class ClientServerTest_NodeHttp_WebSocket_WebSocketClient extends ClientServerServiceTest
{
    public function new()
    {
        super(NodeHttpServerService, WebSocketServerService, WebSocketClientService);
    }
}

class ClientServerTest_NodeHttp_NodeWebSocket_WebSocketClient extends ClientServerServiceTest
{
    public function new()
    {
        super(NodeHttpServerService, NodeWebSocketServerService, WebSocketClientService);
    }
}

class ClientServerServiceTest extends Test
{
    private var factory:IAppFactory;

    private var httpServer:IHttpServerService;
    private var socketServer:ISocketServerService;
    private var client:INetClientService;

   private var httpServerImpl:Class<IHttpServerService>;
   private var socketServerImpl:Class<ISocketServerService>;
   private var clientImpl:Class<INetClientService>;

    public function new(httpServerImpl:Class<IHttpServerService>, socketServerImpl:Class<ISocketServerService>, 
        clientImpl:Class<INetClientService>)
    {
        super();

        this.httpServerImpl = httpServerImpl;
        this.socketServerImpl = socketServerImpl;
        this.clientImpl = clientImpl;
    }

    public function setupClass():Void
    {}

    @:timeout(5000)
    public function setup(async:Async):Void
    {
        factory = new AppFactory();
        factory.mapToValue(IAppFactory, factory);

        factory.mapToType(IHttpServerService, httpServerImpl);
        factory.mapToType(ISocketServerService, socketServerImpl);
        factory.mapToType(INetClientService, clientImpl);

        final host:String = "127.0.0.1";
        final httpPort:Int = 3000;
        final tcpPort:Int = 3001;

        factory.mapClassNameToValue("String", host, "IHttpServerService_host");
        factory.mapClassNameToValue("String", host, "ISocketServerService_host");
        factory.mapClassNameToValue("Int", httpPort, "IHttpServerService_port");
        factory.mapClassNameToValue("Int", tcpPort, "ISocketServerService_port");

        factory.mapClassNameToValue("String", host, "INetClientService_httpHost");
        factory.mapClassNameToValue("String", host, "INetClientService_tcpHost");
        factory.mapClassNameToValue("Int", httpPort, "INetClientService_httpPort");
        factory.mapClassNameToValue("Int", tcpPort, "INetClientService_tcpPort");

         httpServer = factory.getInstance(IHttpServerService);
         httpServer.addMessageListener(NetServerServiceMessageType.Opened, m -> {
             socketServer = factory.getInstance(ISocketServerService);
             socketServer.addMessageListener(NetServerServiceMessageType.Opened, m -> async.done());
         });
    }

    @:timeout(5000)
    public function teardown(async:Async):Void
    {
        var complete:Void -> Void = () -> {
             httpServer.dispose();
            socketServer.dispose();
            async.done();
        };

        var closeSocketServer:Void -> Void = () -> {
            if (socketServer.isOpened)
            {
                socketServer.addMessageListener(NetServerServiceMessageType.Closed, m -> complete());
                socketServer.close();
            } else
            {
                complete();
            }
        };

         if (httpServer.isOpened)
         {
             httpServer.addMessageListener(NetServerServiceMessageType.Closed, m -> closeSocketServer());
             httpServer.close();
         } else
         {
            closeSocketServer();
         }
    }

    @:timeout(1000)
    public function testClose(async:Async):Void
    {
        httpServer.addMessageListener(NetServerServiceMessageType.Closed, m -> {
            socketServer.addMessageListener(NetServerServiceMessageType.Closed, m -> {
                Assert.isFalse(socketServer.isOpened);

                async.done();
            });

            Assert.isFalse(httpServer.isOpened);

            socketServer.close();
        });

        httpServer.close();
    }

    @:timeout(1000)
    public function testHandlerHttpPost(async:Async):Void
    {
        var request:RequestResponse = {
            id: "test",
            data: "Dummy request"
        };

        httpServer.startListen({id: "/test"});
        httpServer.addMessageListener(NetServerServiceMessageType.GotRequest, m -> {
            Assert.equals(request.data, httpServer.requestData.data);

            httpServer.sendResponse({id: httpServer.requestData.id, data: "Success"});
        });

        client = factory.getInstance(INetClientService);
        client.addMessageListener(NetClientServiceMessageType.HttpResponse, m -> {
            Assert.equals("Success", client.responseData.data);
            async.done();
        });

        client.send(request, RequestType.Post);
    }

    @:timeout(1000)
    public function testHandlerHttpGet(async:Async):Void
    {
        var request:RequestResponse = {
            id: "test",
            data: "{\"data\":\"Dummy request\"}"
        };

        httpServer.startListen({id: "/test"});
        httpServer.addMessageListener(NetServerServiceMessageType.GotRequest, m -> {
            Assert.equals(request.data, httpServer.requestData.data);

            httpServer.sendResponse({id: httpServer.requestData.id, data: "Success"});
        });

        client = factory.getInstance(INetClientService);
        client.addMessageListener(NetClientServiceMessageType.HttpResponse, m -> {
            Assert.equals("Success", client.responseData.data);
            async.done();
        });

        client.send(request, RequestType.Get);
    }

    @:timeout(1000)
    public function testHandlerHttpGetWithQueryParams(async:Async):Void
    {
        var request:RequestResponse = {
            id: "test?param_1=preved&param_2=boga"
        };

        httpServer.startListen({id: "/test"});
        httpServer.addMessageListener(NetServerServiceMessageType.GotRequest, m -> {
            Assert.equals(httpServer.getQueryParam("param_1"), "preved");
            Assert.equals(httpServer.getQueryParam("param_2"), "boga");

            httpServer.sendResponse({id: httpServer.requestData.id, data: "Success"});
        });

        client = factory.getInstance(INetClientService);
        client.addMessageListener(NetClientServiceMessageType.HttpResponse, m -> {
            Assert.equals("Success", client.responseData.data);
            async.done();
        });

        client.send(request, RequestType.Get);
    }

    @:timeout(1000)
    public function testHandlerTcpConnectServer(async:Async):Void
    {
        socketServer.addMessageListener(SocketServerServiceMessageType.ClientDisconnected, m -> {
            Assert.equals(0, socketServer.connectionsCount);

            async.done();
        });
        socketServer.addMessageListener(SocketServerServiceMessageType.ClientConnected, m -> {
            Assert.equals(1, socketServer.connectionsCount);

            socketServer.disconnectClient(socketServer.connectedClientId);
        });

        client = factory.getInstance(INetClientService);
        client.connect();
    }

    @:timeout(1000)
    public function testHandlerTcpConnectDisconnectClient(async:Async):Void
    {
        client = factory.getInstance(INetClientService);

        Assert.isFalse(client.isConnected);

        client.addMessageListener(NetClientServiceMessageType.Connected, m -> {
            Assert.isTrue(client.isConnected);

            client.disconnect();
        });
        client.addMessageListener(NetClientServiceMessageType.Disconnected, m -> {
            Assert.isFalse(client.isConnected);

            async.done();
        });

        client.connect();
    }

    @:timeout(1000)
    public function testHandlerTcpRequestResponse(async:Async):Void
    {
        client = factory.getInstance(INetClientService);

        client.addMessageListener(NetClientServiceMessageType.Connected, m -> {
            var json:Dynamic = {people: []};
            for (i in 0...1)
            {
                json.people.push({
                    firstName: "Anton",
                    lastName: "Nefjodov",
                    age: 35
                });
            }

            client.send({id: "test", data: json}, RequestType.Tcp);
        });

        client.addMessageListener(NetClientServiceMessageType.TcpResponse, m -> {
            Assert.equals("test", client.responseData.id);
            Assert.equals("Preved", client.responseData.data);

            client.disconnect();
            async.done();
        });

        socketServer.addMessageListener(NetServerServiceMessageType.GotRequest, m -> {
            Assert.equals("Anton", socketServer.requestData.data.people[0].firstName);

            socketServer.sendResponse(socketServer.connectedClientId, {id: "test", data: "Preved"});
        });

        socketServer.startListen({id: "test"});
        client.connect();
    }
}