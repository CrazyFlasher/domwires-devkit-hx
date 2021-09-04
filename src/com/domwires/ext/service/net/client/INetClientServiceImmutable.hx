package com.domwires.ext.service.net.client;

interface INetClientServiceImmutable extends IServiceIImmutable
{
    var isConnected(get, never):Bool;
    var responseData(get, never):String;
}
