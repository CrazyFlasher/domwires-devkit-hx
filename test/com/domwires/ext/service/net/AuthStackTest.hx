package com.domwires.ext.service.net;
import com.domwires.ext.service.net.client.impl.WebSocketClientService;
import com.domwires.ext.service.net.server.socket.impl.WebSocketServerService;
import com.domwires.core.common.AbstractDisposable;
import com.domwires.core.factory.AppFactory;
import com.domwires.core.factory.IAppFactory;
import com.domwires.core.mvc.message.IMessage;
import com.domwires.ext.service.net.client.impl.NodeNetClientService;
import com.domwires.ext.service.net.client.INetClientService;
import com.domwires.ext.service.net.client.NetClientServiceMessageType;
import com.domwires.ext.service.net.client.RequestType;
import com.domwires.ext.service.net.db.DataBaseServiceMessageType;
import com.domwires.ext.service.net.db.IDataBaseService;
import com.domwires.ext.service.net.db.impl.NodeMongoDatabaseService;
import com.domwires.ext.service.net.server.NetServerServiceMessageType;
import com.domwires.ext.service.net.server.socket.impl.NodeSocketServerService;
import com.domwires.ext.service.net.server.socket.ISocketServerService;
import utest.Assert;
import utest.Async;
import utest.Test;

class AuthStackTest_NodeSocket_NodeMongoDb_NodeClient extends AuthStackTest
{
    public function new()
    {
        super(NodeSocketServerService, NodeMongoDatabaseService, NodeNetClientService);
    }
}

class AuthStackTest_WebSocket_NodeMongoDb_WebSocketClient extends AuthStackTest
{
    public function new()
    {
        super(WebSocketServerService, NodeMongoDatabaseService, WebSocketClientService);
    }
}

class AuthStackTest extends Test
{
    private var server:ISocketServerService;
    private var database:NodeMongoDatabaseService;
    private var client:INetClientService;
    private var dbServer:DbServer;

    private var socketServerImpl:Class<ISocketServerService>;
    private var dbImp:Class<IDataBaseService>;
    private var clientImpl:Class<INetClientService>;

    public function new(socketServerImpl:Class<ISocketServerService>, dbImp:Class<IDataBaseService>,
                        clientImpl:Class<INetClientService>)
    {
        super();

        this.socketServerImpl = socketServerImpl;
        this.dbImp = dbImp;
        this.clientImpl = clientImpl;
    }

    @:timeout(2000)
    public function setupClass(async:Async):Void
    {
        var factory:IAppFactory = new AppFactory();
        factory.mapToValue(IAppFactory, factory);

        factory.mapClassNameToType(ISocketServerService, socketServerImpl);
        factory.mapToType(INetClientService, clientImpl);
        factory.mapToType(IDataBaseService, dbImp);
        factory.mapClassNameToType("Abstract<Dynamic>", AuthSocketClientData, "ISocketClient_data");

        final host:String = "127.0.0.1";
        final httpPort:Int = 3000;
        final tcpPort:Int = 3001;

        factory.mapClassNameToValue("String", host, "ISocketServerService_host");
        factory.mapClassNameToValue("Int", tcpPort, "ISocketServerService_port");

        factory.mapClassNameToValue("String", host, "INetClientService_httpHost");
        factory.mapClassNameToValue("String", host, "INetClientService_tcpHost");
        factory.mapClassNameToValue("Int", httpPort, "INetClientService_httpPort");
        factory.mapClassNameToValue("Int", tcpPort, "INetClientService_tcpPort");

        factory.mapClassNameToValue("String", "mongodb://" + host + ":27017", "IDataBaseService_uri");
        factory.mapClassNameToValue("String", "test_data_base", "IDataBaseService_dataBaseName");

        database = cast factory.getInstance(IDataBaseService);
        factory.mapToValue(IDataBaseService, database, "db");

        server = factory.getInstance(ISocketServerService);
        factory.mapToValue(ISocketServerService, server, "ss");

        client = factory.getInstance(INetClientService);

        server.addMessageListener(NetServerServiceMessageType.Opened, m -> {
            server.startListen({id: "reg"});
            server.startListen({id: "login"});
            server.startListen({id: "message"});
            
            database.connect();
        });

        dbServer = factory.getInstance(DbServer);
        database.addMessageListener(DataBaseServiceMessageType.Connected, m -> database.createTable("users", ["email"]));
        database.addMessageListener(DataBaseServiceMessageType.CreateTableResult, m -> async.done());
    }

    public function setup():Void
    {
        client.removeAllMessageListeners();
        database.removeAllMessageListeners();
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
    @:depends(testRegisterExists)
    public function testRegisterNoPass(async:Async):Void
    {
        client.addMessageListener(NetClientServiceMessageType.TcpResponse, m -> {
            Assert.equals("ERROR", client.responseData.data);

            async.done();
        });

        client.send({id: "reg", data: {email: "anton@javelin.ee"}}, RequestType.Tcp);
    }

    @:timeout(2000)
    @:depends(testRegisterNoPass)
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

class DbServer extends AbstractDisposable
{
    @Inject("db")
    private var db:IDataBaseService;

    @Inject("ss")
    private var ss:ISocketServerService;

    @PostConstruct
    private function init():Void
    {
        ss.addMessageListener(NetServerServiceMessageType.GotRequest, gotRequest);
    }

    private function gotRequest(m:IMessage):Void
    {
        var clientId:Int = ss.requestFromClientId;
        var requestData:RequestResponse = ss.requestData;

        if (requestData.id == "reg")
        {
            var handleInsertResult:IMessage -> Void = (m:IMessage) -> ss.sendResponse(clientId, {id: "reg", data: "OK"});
            var handleInsertError:IMessage -> Void = (m:IMessage) -> ss.sendResponse(clientId, {id: "reg", data: "ERROR"});

            db.addMessageListener(DataBaseServiceMessageType.InsertResult, handleInsertResult);
            db.addMessageListener(DataBaseServiceMessageType.InsertError, handleInsertError);

            if (requestData.data.password == null)
            {
                ss.sendResponse(clientId, {id: "reg", data: "ERROR"});
            } else
            {
                db.insert("users", [{email: requestData.data.email, password: requestData.data.password}]);
            }
        } else
        if (requestData.id == "login")
        {
            var handleFindResult:IMessage -> Void = (m:IMessage) -> {

                if (db.result.password == requestData.data.password)
                {
                    cast (ss.getClientDataById(clientId), AuthSocketClientData).isAuthorized = true;

                    ss.sendResponse(clientId, {id: "login", data: "OK"});
                } else
                {
                    ss.sendResponse(clientId, {id: "login", data: "ERROR"});
                }
            };

            var handleFindError:IMessage -> Void = (m:IMessage) -> ss.sendResponse(clientId, {id: "login", data: "ERROR"});

            db.addMessageListener(DataBaseServiceMessageType.FindResult, handleFindResult);
            db.addMessageListener(DataBaseServiceMessageType.FindError, handleFindError);

            db.find("users", {email: requestData.data.email});
        } else
        if (requestData.id == "message")
        {
            if (!cast (ss.getClientDataById(clientId), AuthSocketClientData).isAuthorized)
            {
                ss.sendResponse(clientId, {id: "message", data: "ERROR"});
            } else
            {
                ss.sendResponse(clientId, {id: "message", data: "OK"});
            }
        }
    }
}

class AuthSocketClientData
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
