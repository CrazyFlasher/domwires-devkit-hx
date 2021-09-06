package com.domwires.ext.service.net.server;

interface INetServerService extends INetServerServiceImmutable extends IService
{
    function startListen(request:RequestResponse, type:RequestType):INetServerService;
    function stopListen(request:RequestResponse, type:RequestType):INetServerService;
    function sendTcpResponse(clientId:Int, response:RequestResponse):INetServerService;
    function close(?type:ServerType):INetServerService;
}
