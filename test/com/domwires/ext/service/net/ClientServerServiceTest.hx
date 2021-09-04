package com.domwires.ext.service.net;

import js.node.Net;
import js.node.net.Socket;
import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import com.domwires.ext.service.net.client.impl.NodeNetClientService;
import com.domwires.ext.service.net.client.INetClientService;
import com.domwires.ext.service.net.client.NetClientServiceMessageType;
import com.domwires.ext.service.net.server.impl.NodeNetServerService;
import com.domwires.ext.service.net.server.INetServerService;
import com.domwires.ext.service.net.server.NetServerServiceMessageType;
import js.node.http.ServerResponse;
import js.node.url.URL;
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

    @:timeout(1000)
    public function teardown(async:Async):Void
    {
        var httpClosed:Bool = !server.isOpened(ServerType.Http);
        var tcpClosed:Bool = !server.isOpened(ServerType.Tcp);

        var complete:Void -> Void = () ->
        {
            server.dispose();
            async.done();
        };

        server.addMessageListener(NetServerServiceMessageType.TcpClosed, m ->
        {
            tcpClosed = true;

            if (httpClosed)
            {
                complete();
            }
        });

        server.addMessageListener(NetServerServiceMessageType.HttpClosed, m ->
        {
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
        server.addMessageListener(NetServerServiceMessageType.HttpClosed, m ->
        {
            httpClosed = true;

            Assert.isFalse(server.isOpened(ServerType.Http));

            server.close(ServerType.Tcp);

            if (tcpClosed)
                async.done();
        });

        server.addMessageListener(NetServerServiceMessageType.TcpClosed, m ->
        {
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
            data: "Dummy request",
            type: RequestType.Post
        };

        server = factory.getInstance(INetServerService);
        server.startListen({id: "/test", type: RequestType.Post});
        server.addMessageListener(NetServerServiceMessageType.GotHttpRequest, m ->
        {
            Assert.equals(request.data, server.requestData);
        });

        client = factory.getInstance(INetClientService);
        client.addMessageListener(NetClientServiceMessageType.HttpResponse, m -> 
        {
            Assert.equals("Success", client.responseData);
            async.done();
        });

        client.send(request);
    }

    @:timeout(1000)
    public function testHandlerHttpGet(async:Async):Void
    {
        var request:RequestResponse = {
            id: "test",
            data: "Dummy request",
            type: RequestType.Get
        };

        server = factory.getInstance(INetServerService);
        server.startListen({id: "/test", type: RequestType.Get});
        server.addMessageListener(NetServerServiceMessageType.GotHttpRequest, m ->
        {
            Assert.equals(request.data, server.requestData);
        });

        client = factory.getInstance(INetClientService);
        client.addMessageListener(NetClientServiceMessageType.HttpResponse, m ->
        {
            Assert.equals("Success", client.responseData);
            async.done();
        });

        client.send(request);
    }

    @:timeout(1000)
    public function testHandlerHttpGetWithQueryParams(async:Async):Void
    {
        var request:RequestResponse = {
            id: "test?param_1=preved&param_2=boga",
            type: RequestType.Get
        };

        server = factory.getInstance(INetServerService);
        server.startListen({id: "/test", type: RequestType.Get});
        server.addMessageListener(NetServerServiceMessageType.GotHttpRequest, m ->
        {
            Assert.equals(server.getQueryParam("param_1"), "preved");
            Assert.equals(server.getQueryParam("param_2"), "boga");
        });

        client = factory.getInstance(INetClientService);
        client.addMessageListener(NetClientServiceMessageType.HttpResponse, m ->
        {
            Assert.equals("Success", client.responseData);
            async.done();
        });

        client.send(request);
    }

    @:timeout(1000)
    public function testHandlerTcpConnectServer(async:Async):Void
    {
        server = factory.getInstance(INetServerService);
        server.addMessageListener(NetServerServiceMessageType.ClientConnected, m ->
        {
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

        client.addMessageListener(NetClientServiceMessageType.Connected, m ->
        {
            Assert.isTrue(client.isConnected);

            client.disconnect();
        });
        client.addMessageListener(NetClientServiceMessageType.Disconnected, m ->
        {
            Assert.isFalse(client.isConnected);

            async.done();
        });

        client.connect();
    }

    @:timeout(1000)
    public function testHandlerTcpRequest(async:Async):Void
    {
        server = factory.getInstance(INetServerService);
        client = factory.getInstance(INetClientService);

        client.addMessageListener(NetClientServiceMessageType.Connected, m ->
        {
            var jsonString:String = "";
            for (i in 0...100)
            {
                jsonString += "{\"firstName\": \"Anton\", \"lastName\": \"Nefjodov\", \"age\": 35},";
            }
            jsonString = jsonString.substring(0, jsonString.length - 1);
            jsonString = "{\"people\":[" + jsonString + "]}\n";

            client.send({type: RequestType.Tcp, id: "test", data: jsonString});
        });

        server.addMessageListener(NetServerServiceMessageType.GotTcpData, m ->
        {
            var requestData:String = server.requestData;
            Assert.equals("Anton", haxe.Json.parse(requestData).people[0].firstName);
            client.disconnect();
            async.done();
        });

        client.connect();
    }
}

class DummyClient extends NodeNetClientService
{

}

class DummyServer extends NodeNetServerService
{
    override private function sendHttpResponse(requestUrl:URL, response:ServerResponse):Void
    {
        if (requestUrl.pathname == "/test")
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