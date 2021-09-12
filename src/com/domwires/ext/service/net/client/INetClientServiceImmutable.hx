package com.domwires.ext.service.net.client;

interface INetClientServiceImmutable extends IServiceImmutable
{
    var isConnected(get, never):Bool;
    var responseData(get, never):RequestResponse;
}
