package com.domwires.ext.service.net.server.socket;

interface ISocketServerServiceImmutable extends INetServerServiceImmutable
{
    var connectionsCount(get, never):Int;
    var connectedClientId(get, never):Int;
    var disconnectedClientId(get, never):Int;
    var requestFromClientId(get, never):Int;

    function getClientDataById(clientId:Int):Dynamic;
}
