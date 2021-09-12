package com.domwires.ext.service.net.server.socket;

interface ISocketServerService extends ISocketServerServiceImmutable extends INetServerService
{
    function sendResponse(clientId:Int, response:RequestResponse):ISocketServerService;
    function disconnectClient(clientId:Int):ISocketServerService;
    function disconnectAllClients():ISocketServerService;
}
