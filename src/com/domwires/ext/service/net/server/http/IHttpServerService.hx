package com.domwires.ext.service.net.server.http;

import haxe.DynamicAccess;

interface IHttpServerService extends IHttpServerServiceImmutable extends INetServerService
{
    function sendResponse(response:RequestResponse, statusCode:Int = 200, ?customHeaders:DynamicAccess<String>):IHttpServerService;
}
