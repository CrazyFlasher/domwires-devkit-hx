package com.domwires.ext.service.net.server;

class AbstractNetServerService extends AbstractService implements INetServerService
{
    public var requestData(get, never):RequestResponse;
    private var _requestData:RequestResponse;

    public var isOpened(get, never):Bool;
    private var _isOpened:Bool = false;

    private var reqMap:Map<String, RequestResponse> = [];

    override public function dispose():Void
    {
        close();

        super.dispose();
    }

    public function close():INetServerService
    {
        throw Error.Override;
    }

    override private function initSuccess():Void
    {
        super.initSuccess();

        createServer();
    }

    private function createServer():Void
    {
        throw Error.Override;
    }

    public function startListen(request:RequestResponse):INetServerService
    {
        if (!checkIsOpened())
        {
            return this;
        }

        if (!reqMap.exists(request.id))
        {
            reqMap.set(request.id, request);
        }

        return this;
    }

    public function stopListen(request:RequestResponse):INetServerService
    {
        if (!checkIsOpened())
        {
            return this;
        }

        if (reqMap.exists(request.id))
        {
            reqMap.remove(request.id);
        }

        return this;
    }

    private function get_requestData():RequestResponse
    {
        return _requestData;
    }

    private function get_isOpened():Bool
    {
        return _isOpened;
    }

    private function checkIsOpened():Bool
    {
        if (!checkEnabled()) return false;

        if (!_isOpened)
        {
            trace("Server is not opened!");

            return false;
        }

        return true;
    }
}
