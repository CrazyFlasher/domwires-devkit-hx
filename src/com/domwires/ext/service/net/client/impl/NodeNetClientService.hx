package com.domwires.ext.service.net.client.impl;

import js.node.http.ClientRequest;
import js.node.Http.HttpRequestOptions;
import js.node.http.IncomingMessage;
import js.node.http.Method;
import js.node.Http;
import js.node.net.Socket;
import js.node.Net;

class NodeNetClientService extends AbstractNetClientService implements INetClientService
{
    private var client:Socket;

    override public function connect():INetClientService
    {
        if (!checkEnabled())
        {
            return this;
        }

        if (_isConnected)
        {
            trace("Client already connected!");

            return this;
        }

        client = Net.connect({port: _tcpPort, host: _tcpHost}, () -> {
            client.on(SocketEvent.End, () -> {

                _isConnected = false;

                handleDisconnect();

                dispatchMessage(NetClientServiceMessageType.Disconnected);
            });

            var received:MessageBuffer = new MessageBuffer();

            client.on(SocketEvent.Data, (chunk:String) -> {
                received.push(chunk);
                while (!received.isFinished())
                {
                    var data:String = received.getMessage();
                    var resData:RequestResponse = validateResponse(data);

                    _responseData = {id: resData.id, data: resData.data};

                    handleTcpResponse();

                    dispatchMessage(NetClientServiceMessageType.TcpResponse);
                }
            });

            
            _isConnected = true;

            handleConnect();

            dispatchMessage(NetClientServiceMessageType.Connected);
        });

        return this;
    }

    override public function disconnect():INetClientService
    {
        if (!checkEnabled())
        {
            return this;
        }

        if (!_isConnected)
        {
            trace("Client is disconnected!");

            return this;
        }

        client.end();

        return this;
    }

    override private function sendHttpRequest(request:RequestResponse, type:RequestType):Void
    {
        var method:Method;
        if (type == RequestType.Post)
        {
            method = Method.Post;
        } else
        {
            method = Method.Get;
        }

        var length:Int = (request.data != null ? request.data.length : 0);
        var options:HttpRequestOptions = {
            hostname: _httpHost,
            method: method,
            port: _httpPort,
            path: "/" + request.id,
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Std.string(length)
            }
        };

        var req:ClientRequest = Http.request(options, (message:IncomingMessage) -> {
            var data:String = "";
            message.on("data", (chunk:String) -> {
                data += chunk;
            });
            message.on("end", () -> {
                _responseData = {id: message.url, data: data};

                handleHttpResponse(data);

                dispatchMessage(NetClientServiceMessageType.HttpResponse);
            });
        });

        if (request.data != null)
        {
            req.write(request.data);
        }
        
        req.end();
    }

    override private function sendTcpRequest(request:RequestResponse):Void
    {
        client.write(messageToSend);
    }
}
