package com.domwires.ext.service.net.server;

interface INetServerService extends INetServerServiceImmutable extends IService
{
    function startListen(request:RequestResponse):INetServerService;
    function stopListen(request:RequestResponse):INetServerService;
    function sendTcpData(value:RequestResponse):INetServerService;
    function close(?type:ServerType):INetServerService;
}
