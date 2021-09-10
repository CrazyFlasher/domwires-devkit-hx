package com.domwires.ext.service.net;
import com.domwires.core.mvc.message.IMessage;
import js.node.net.Socket;
import com.domwires.ext.service.net.db.impl.NodeMongoDatabaseService;
import com.domwires.ext.service.net.client.impl.NodeNetClientService;
import com.domwires.ext.service.net.server.impl.NodeNetServerService;
import com.domwires.ext.service.net.client.NetClientServiceMessageType;
import com.domwires.ext.service.net.db.DataBaseServiceMessageType;
import com.domwires.ext.service.net.server.NetServerServiceMessageType;
import utest.Async;
import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import com.domwires.ext.service.net.client.INetClientService;
import com.domwires.ext.service.net.db.IDataBaseService;
import com.domwires.ext.service.net.server.INetServerService;
import utest.Assert;
import utest.Test;

class AuthStackTest extends Test
{
    private var server:INetServerService;
    private var database:Db;
    private var client:INetClientService;

    @:timeout(200000)
    public function setupClass(async:Async):Void
    {
        var factory:IAppFactory = new AppFactory();

        factory.mapToValue(IAppFactory, factory);
        factory.mapToType(INetServerService, Server);
        factory.mapToType(INetClientService, Client);
        factory.mapToType(IDataBaseService, Db);
        factory.mapToType(SocketClient, AuthSocketClient);

        factory.mapClassNameToValue("String", "127.0.0.1", "INetServerService_httpHost");
        factory.mapClassNameToValue("String", "127.0.0.1", "INetServerService_tcpHost");
        factory.mapClassNameToValue("Int", 3000, "INetServerService_httpPort");
        factory.mapClassNameToValue("Int", 3001, "INetServerService_tcpPort");

        factory.mapClassNameToValue("String", "127.0.0.1", "INetClientService_httpHost");
        factory.mapClassNameToValue("String", "127.0.0.1", "INetClientService_tcpHost");
        factory.mapClassNameToValue("Int", 3000, "INetClientService_httpPort");
        factory.mapClassNameToValue("Int", 3001, "INetClientService_tcpPort");

        factory.mapClassNameToValue("String", "mongodb://127.0.0.1:27017", "IDataBaseService_uri");
        factory.mapClassNameToValue("String", "test_data_base", "IDataBaseService_dataBaseName");

        database = cast factory.getInstance(IDataBaseService);
        factory.mapToValue(Db, database, "db");

        server = factory.getInstance(INetServerService);
        client = factory.getInstance(INetClientService);

        server.addMessageListener(NetServerServiceMessageType.Opened, m -> database.connect());
        database.addMessageListener(DataBaseServiceMessageType.Connected, m -> database.createTable("users", ["email"]));
        database.addMessageListener(DataBaseServiceMessageType.CreateTableResult, m -> async.done());

        server.startListen({id: "reg"}, RequestType.Tcp);
        server.startListen({id: "login"}, RequestType.Tcp);
        server.startListen({id: "message"}, RequestType.Tcp);
    }

    public function setup():Void
    {
        server.removeAllMessageListeners();
        database.removeAllMessageListeners();
        client.removeAllMessageListeners();
    }

    @:timeout(2000)
    public function teardownClass(async:Async):Void
    {
        client.disconnect();
        database.dropTable("users");
        database.disconnect();
        server.close();

        server.addMessageListener(NetServerServiceMessageType.Closed, m -> async.done());
    }

    @:timeout(2000)
    public function testRegisterOk(async:Async):Void
    {
        client.addMessageListener(NetClientServiceMessageType.Connected, m -> {
            client.send({id: "reg", data: {email: "anton@javelin.ee", password: "123"}}, RequestType.Tcp);
        });
        client.addMessageListener(NetClientServiceMessageType.TcpResponse, m -> {
            Assert.equals("OK", client.responseData.data);

            async.done();
        });

        client.connect();
    }

    @:timeout(2000)
    @:depends(testRegisterOk)
    public function testRegisterExists(async:Async):Void
    {
        client.addMessageListener(NetClientServiceMessageType.TcpResponse, m -> {
            Assert.equals("ERROR", client.responseData.data);

            async.done();
        });

        client.send({id: "reg", data: {email: "anton@javelin.ee", password: "123"}}, RequestType.Tcp);
    }

    @:timeout(2000)
    @:depends(testRegisterOk)
    public function testRegisterNoPass(async:Async):Void
    {
        client.addMessageListener(NetClientServiceMessageType.TcpResponse, m -> {
            Assert.equals("ERROR", client.responseData.data);

            async.done();
        });

        client.send({id: "reg", data: {email: "anton@javelin.ee", password: "123"}}, RequestType.Tcp);
    }

    @:timeout(2000)
    @:depends(testRegisterOk)
    public function testLoginNotFound(async:Async):Void
    {
        client.addMessageListener(NetClientServiceMessageType.TcpResponse, m -> {
            Assert.equals("ERROR", client.responseData.data);

            async.done();
        });

        client.send({id: "login", data: {email: "anton@javelin.ee2", password: "123"}}, RequestType.Tcp);
    }

    @:timeout(2000)
    @:depends(testLoginNotFound)
    public function testLoginWrongPass(async:Async):Void
    {
        client.addMessageListener(NetClientServiceMessageType.TcpResponse, m -> {
            Assert.equals("ERROR", client.responseData.data);

            async.done();
        });

        client.send({id: "login", data: {email: "anton@javelin.ee", password: "111"}}, RequestType.Tcp);
    }

    @:timeout(2000)
    @:depends(testLoginWrongPass)
    public function testSendMessageError(async:Async):Void
    {
        client.addMessageListener(NetClientServiceMessageType.TcpResponse, m -> {
            Assert.equals("ERROR", client.responseData.data);

            async.done();
        });

        client.send({id: "message", data: {message: "ololo"}}, RequestType.Tcp);
    }

    @:timeout(2000)
    @:depends(testSendMessageError)
    public function testLoginOk(async:Async):Void
    {
        client.addMessageListener(NetClientServiceMessageType.TcpResponse, m -> {
            Assert.equals("OK", client.responseData.data);

            async.done();
        });

        client.send({id: "login", data: {email: "anton@javelin.ee", password: "123"}}, RequestType.Tcp);
    }

    @:timeout(2000)
    @:depends(testLoginOk)
    public function testSendMessageOk(async:Async):Void
    {
        client.addMessageListener(NetClientServiceMessageType.TcpResponse, m -> {
            Assert.equals("OK", client.responseData.data);

            async.done();
        });

        client.send({id: "message", data: {message: "ololo"}}, RequestType.Tcp);
    }
    
}

class Server extends NodeNetServerService
{
    @Inject("db")
    private var db:Db;

    override private function handleTcpRequest(clientId:Int):Void
    {
        super.handleTcpRequest(clientId);

        if (_requestData.id == "reg")
        {
            var handleInsertResult:IMessage -> Void = (m:IMessage) -> {
                sendTcpResponse(clientId, {id: "reg", data: "OK"});
            };

            var handleInsertError:IMessage -> Void = (m:IMessage) -> {
                sendTcpResponse(clientId, {id: "reg", data: "ERROR"});
            };

            db.addMessageListener(DataBaseServiceMessageType.InsertResult, handleInsertResult);
            db.addMessageListener(DataBaseServiceMessageType.InsertError, handleInsertError);

            if (_requestData.data.password == null)
            {
                sendTcpResponse(clientId, {id: "reg", data: "ERROR"});
            } else
            {
                db.insert("users", [{email: _requestData.data.email, password: _requestData.data.password}]);
            }
        } else
        if (_requestData.id == "login")
        {
            var handleFindResult:IMessage -> Void = (m:IMessage) -> {

                if (db.getResult().password == _requestData.data.password)
                {
                    cast (clientIdMap.get(clientId), AuthSocketClient).isAuthorized = true;

                    sendTcpResponse(clientId, {id: "login", data: "OK"});
                } else
                {
                    sendTcpResponse(clientId, {id: "login", data: "ERROR"});
                }
            };

            var handleFindError:IMessage -> Void = (m:IMessage) -> {
                sendTcpResponse(clientId, {id: "login", data: "ERROR"});
            };

            db.addMessageListener(DataBaseServiceMessageType.FindResult, handleFindResult);
            db.addMessageListener(DataBaseServiceMessageType.FindError, handleFindError);

            db.find("users", {email: _requestData.data.email});
        } else
        if (_requestData.id == "message")
        {
            if (!cast (clientIdMap.get(clientId), AuthSocketClient).isAuthorized)
            {
                sendTcpResponse(clientId, {id: "message", data: "ERROR"});
            } else
            {
                sendTcpResponse(clientId, {id: "message", data: "OK"});
            }
        }
    }

    public function getClientById(clientId:Int):AuthSocketClient
    {
        return cast clientIdMap.get(clientId);
    }
}

class AuthSocketClient extends SocketClient
{
    private var _isAuthorized:Bool = false;

    public var isAuthorized(get, set):Bool;

    private function get_isAuthorized():Bool
    {
        return _isAuthorized;
    }

    private function set_isAuthorized(value:Bool):Bool
    {
        return _isAuthorized = value;
    }
}

class Client extends NodeNetClientService
{

}

class Db extends NodeMongoDatabaseService
{
    public function getResult():Dynamic
    {
        return result;
    }

    public function getError():MongoError
    {
        return error;
    }
}
