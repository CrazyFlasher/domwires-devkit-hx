package com.domwires.ext.service.net.server;

enum NetServerServiceMessageType
{
    HttpClosed;
    TcpClosed;
    ClientConnected;
    ClientDisconnected;
    GotHttpRequest;
    SendHttpResponse;
    GotTcpData;
}
