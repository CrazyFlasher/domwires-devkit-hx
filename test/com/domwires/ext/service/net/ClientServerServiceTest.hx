package com.domwires.ext.service.net;

import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import com.domwires.ext.service.net.client.impl.NodeNetClientService;
import com.domwires.ext.service.net.client.INetClientService;
import com.domwires.ext.service.net.client.NetClientServiceMessageType;
import com.domwires.ext.service.net.server.impl.NodeNetServerService;
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
    private var server:INetServerService;
    private var client:INetClientService;

    public function setupClass():Void
    {}

    public function teardownClass():Void
    {}

    public function setup():Void
    {
        factory = new AppFactory();

        factory.mapToType(INetServerService, DummyServer);
        factory.mapToType(INetClientService, DummyClient);

        factory.mapClassNameToValue("String", "127.0.0.1", "INetServerService_httpHost");
        factory.mapClassNameToValue("String", "127.0.0.1", "INetServerService_tcpHost");
        factory.mapClassNameToValue("Int", 3000, "INetServerService_httpPort");
        factory.mapClassNameToValue("Int", 3001, "INetServerService_tcpPort");

        factory.mapClassNameToValue("String", "127.0.0.1", "INetClientService_httpHost");
        factory.mapClassNameToValue("String", "127.0.0.1", "INetClientService_tcpHost");
        factory.mapClassNameToValue("Int", 3000, "INetClientService_httpPort");
        factory.mapClassNameToValue("Int", 3001, "INetClientService_tcpPort");
    }

    @:timeout(10000)
    public function teardown(async:Async):Void
    {
        var httpClosed:Bool = !server.isOpened(ServerType.Http);
        var tcpClosed:Bool = !server.isOpened(ServerType.Tcp);

        var complete:Void -> Void = () -> {
            server.dispose();
            async.done();
        };

        server.addMessageListener(NetServerServiceMessageType.TcpClosed, m -> {
            tcpClosed = true;

            if (httpClosed)
            {
                complete();
            }
        });

        server.addMessageListener(NetServerServiceMessageType.HttpClosed, m -> {
            httpClosed = true;

            if (tcpClosed)
            {
                complete();
            }
        });

        server.close();
    }

    @:timeout(1000)
    public function testClose(async:Async):Void
    {
        var httpClosed:Bool = false;
        var tcpClosed:Bool = false;

        server = factory.getInstance(INetServerService);
        server.addMessageListener(NetServerServiceMessageType.HttpClosed, m -> {
            httpClosed = true;

            Assert.isFalse(server.isOpened(ServerType.Http));

            server.close(ServerType.Tcp);

            if (tcpClosed)
                async.done();
        });

        server.addMessageListener(NetServerServiceMessageType.TcpClosed, m -> {
            tcpClosed = true;

            Assert.isFalse(server.isOpened(ServerType.Tcp));

            if (httpClosed)
                async.done();
        });

        server.close(ServerType.Http);
    }

    @:timeout(1000)
    public function testHandlerHttpPost(async:Async):Void
    {
        var request:RequestResponse = {
            id: "test",
            data: "Dummy request"
        };

        server = factory.getInstance(INetServerService);
        server.startListen({id: "/test"}, RequestType.Post);
        server.addMessageListener(NetServerServiceMessageType.GotHttpRequest, m -> {
            Assert.equals(request.data, server.requestData.data);
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

        server = factory.getInstance(INetServerService);
        server.startListen({id: "/test"}, RequestType.Get);
        server.addMessageListener(NetServerServiceMessageType.GotHttpRequest, m -> {
            Assert.equals(request.data, server.requestData.data);
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

        server = factory.getInstance(INetServerService);
        server.startListen({id: "/test"}, RequestType.Get);
        server.addMessageListener(NetServerServiceMessageType.GotHttpRequest, m -> {
            Assert.equals(server.getQueryParam("param_1"), "preved");
            Assert.equals(server.getQueryParam("param_2"), "boga");
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
        server = factory.getInstance(INetServerService);
        server.addMessageListener(NetServerServiceMessageType.ClientConnected, m -> {
            Assert.equals(1, server.connectionsCount);

            client.disconnect();
            async.done();
        });

        client = factory.getInstance(INetClientService);
        client.connect();
    }

    @:timeout(1000)
    public function testHandlerTcpConnectDisconnectClient(async:Async):Void
    {
        server = factory.getInstance(INetServerService);
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
        server = factory.getInstance(INetServerService);
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

        server.addMessageListener(NetServerServiceMessageType.GotTcpRequest, m -> {
            Assert.equals("Anton", server.requestData.data.people[0].firstName);

            server.sendTcpResponse(cast (server, DummyServer).getClientId(), {id: "test", data: "Preved"});
        });

        server.startListen({id: "test"}, RequestType.Tcp);
        client.connect();
    }
}

class DummyClient extends NodeNetClientService
{

}

class DummyServer extends NodeNetServerService
{
    private var testClientId:Int;

    override private function sendHttpResponse(response:ServerResponse):Void
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