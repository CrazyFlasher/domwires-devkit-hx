package com.domwires.ext.service.net;

import com.domwires.ext.service.net.server.socket.SocketServerServiceMessageType;
import com.domwires.ext.service.net.server.socket.impl.NodeSocketServerService;
import com.domwires.ext.service.net.server.http.impl.NodeHttpServerService;
import com.domwires.ext.service.net.server.socket.ISocketServerService;
import com.domwires.ext.service.net.server.http.IHttpServerService;
import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import com.domwires.ext.service.net.client.impl.NodeNetClientService;
import com.domwires.ext.service.net.client.INetClientService;
import com.domwires.ext.service.net.client.NetClientServiceMessageType;
import com.domwires.ext.service.net.server.INetServerService;
import com.domwires.ext.service.net.server.NetServerServiceMessageType;
import js.node.http.ServerResponse;
import js.node.net.Socket;
import utest.Assert;
import utest.Async;
import utest.Test;

class ClientServerServiceTest extends Test
{
    private var factory:IAppFactory;
    private var httpServer:IHttpServerService;
    private var socketServer:ISocketServerService;
    private var client:INetClientService;

    public function setupClass():Void
    {}

    public function teardownClass():Void
    {}

    @:timeout(5000)
    public function setup(async:Async):Void
    {
        factory = new AppFactory();

        factory.mapToType(IHttpServerService, DummyHttpServer);
        factory.mapToType(ISocketServerService, DummySocketServer);
        factory.mapToType(INetClientService, DummyClient);

        factory.mapClassNameToValue("String", "127.0.0.1", "IHttpServerService_host");
        factory.mapClassNameToValue("String", "127.0.0.1", "ISocketServerService_host");
        factory.mapClassNameToValue("Int", 3000, "IHttpServerService_port");
        factory.mapClassNameToValue("Int", 3001, "ISocketServerService_port");

        factory.mapClassNameToValue("String", "127.0.0.1", "INetClientService_httpHost");
        factory.mapClassNameToValue("String", "127.0.0.1", "INetClientService_tcpHost");
        factory.mapClassNameToValue("Int", 3000, "INetClientService_httpPort");
        factory.mapClassNameToValue("Int", 3001, "INetClientService_tcpPort");

        httpServer = factory.getInstance(IHttpServerService);
        httpServer.addMessageListener(NetServerServiceMessageType.Opened, m -> {
            socketServer = factory.getInstance(ISocketServerService);
            socketServer.addMessageListener(NetServerServiceMessageType.Opened, m -> async.done());
        });
    }

    @:timeout(50000)
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
        });

        client = factory.getInstance(INetClientService);
        client.addMessageListener(NetClientServiceMessageType.HttpResponse, m -> {
            Assert.equals("Success", client.responseData.data);
            async.done();
        });

        client.send(request, RequestType.Get);
    }

    @:timeout(100000)
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

    @:timeout(10000)
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

            socketServer.sendResponse(cast (socketServer, DummySocketServer).getClientId(), {id: "test", data: "Preved"});
        });

        socketServer.startListen({id: "test"});
        client.connect();
    }
}

class DummyClient extends NodeNetClientService
{

}

class DummyHttpServer extends NodeHttpServerService
{
    override private function sendResponse(response:ServerResponse):Void
    {
        if (requestData.id == "/test")
        {
            response.writeHead(200, {
                "Content-Type": "text/plain; charset=utf-8"
            });

            response.write("Success");
        } else
        {
            response.writeHead(404);
        }

        response.end();
    }
}

class DummySocketServer extends NodeSocketServerService
{
    private var testClientId:Int;

    override private function handleClientConnected(socket:Socket):Void
    {
        super.handleClientConnected(socket);

        testClientId = untyped socket.id;
    }

    public function getClientId():Int
    {
        return testClientId;
    }
}