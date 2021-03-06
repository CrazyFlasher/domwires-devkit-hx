package com.domwires.ext.service.net.server.socket;

import com.domwires.core.common.AbstractDisposable;
import haxe.Json;
import js.lib.Error;

class AbstractSocketServerService extends AbstractNetServerService implements ISocketServerService
{
    @Inject("ISocketServerService_enabled")
    @Optional
    private var __enabled:Bool;

    @Inject("ISocketServerService_port")
    private var _port:Int;

    @Inject("ISocketServerService_host")
    private var _host:String;

    public var connectionsCount(get, never):Int;
    private var _connectionsCount:Int = 0;

    public var connectedClientId(get, never):Int;
    private var _connectedClientId:Int;

    public var disconnectedClientId(get, never):Int;
    private var _disconnectedClientId:Int;

    public var requestFromClientId(get, never):Int;
    private var _requestFromClientId:Int;

    private var clientIdMap:Map<Int, ISocketClient> = [];

    override private function init():Void
    {
        initResult(__enabled);
    }

    private function validateRequest(clientId:Int, data:String):RequestResponse
    {
        var reqData:RequestResponse;

        try
        {
            reqData = Json.parse(data);
        } catch (e:Error)
        {
            clientError("Request should be a JSON string: " + data, clientId);

            return null;
        }

        if (reqData.id == null)
        {
            clientError("Request Json should contain \"id\" field!: " + data, clientId);

            return null;
        }

        return reqData;
    }

    public function sendResponse(clientId:Int, response:RequestResponse):ISocketServerService
    {
        if (!clientIdMap.exists(clientId))
        {
            throw Error.Custom("Client with id " + clientId + " doesn't exist!");
        }

        clientIdMap.get(clientId).write(Json.stringify(response) + "\n");

        return this;
    }

    public function disconnectClient(clientId:Int):ISocketServerService
    {
        if (!checkIsOpened())
        {
            return this;
        }

        if (!clientIdMap.exists(clientId))
        {
            trace("Cannot disconnect client. Not found: " + clientId);

            return this;
        }

        closeClient(clientId);

        return this;
    }

    public function disconnectAllClients():ISocketServerService
    {
        if (!checkIsOpened())
        {
            return this;
        }

        for (clientId in clientIdMap.keys())
        {
            closeClient(clientId);
        }

        return this;
    }

    public function getClientDataById(clientId:Int):Dynamic
    {
        if (!checkIsOpened())
        {
            return null;
        }

        return clientIdMap.get(clientId).data;
    }

    private function get_connectionsCount():Int
    {
        return _connectionsCount;
    }

    private function clientError(message:String, clientId:Int):Void
    {
        trace("Client Error: " + message);

        closeClient(clientId);
    }

    private function closeClient(clientId:Int):Void
    {
        clientIdMap.get(clientId).close();
    }

    private function get_disconnectedClientId():Int
    {
        return _disconnectedClientId;
    }

    private function get_connectedClientId():Int
    {
        return _connectedClientId;
    }

    private function get_requestFromClientId():Int
    {
        return _requestFromClientId;
    }
}

class AbstractSocketClient extends AbstractDisposable implements ISocketClient
{
    public var data(get, never):Dynamic;
    private var _data:Dynamic;

    public var id(get, never):Int;
    private var _id:Int;

    public function new(id:Int, data:Dynamic)
    {
        super();

        _id = id;
        _data = data;
    }

    private function get_id():Int
    {
        return _id;
    }

    private function get_data():Dynamic
    {
        return _data;
    }

    public function close():Void
    {
        throw Error.Override;
    }

    public function write(data:String):Void
    {
        throw Error.Override;
    }
}