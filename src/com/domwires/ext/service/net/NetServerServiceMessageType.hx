package com.domwires.ext.service.net;

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
