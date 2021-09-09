package com.domwires.ext.service.net.server;

enum NetServerServiceMessageType
{
    ClientConnected;
    ClientDisconnected;
    GotHttpRequest;
    SendHttpResponse;
    GotTcpRequest;
    Opened;
    Closed;
}
