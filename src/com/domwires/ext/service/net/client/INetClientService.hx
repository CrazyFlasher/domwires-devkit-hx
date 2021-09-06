package com.domwires.ext.service.net.client;

interface INetClientService extends INetClientServiceImmutable extends IService
{
    function connect():INetClientService;
    function disconnect():INetClientService;
    function send(request:RequestResponse, type:RequestType):INetClientService;
}
