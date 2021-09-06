package com.domwires.ext.service.net;

class MessageBuffer
{
    private var delimiter:String;
    private var buffer:String;

    public function new(delimiter:String = "\n")
    {
        this.delimiter = delimiter;
        this.buffer = "";
    }

    public function isFinished():Bool
    {
        if (buffer.length == 0 || buffer.indexOf(delimiter) == -1)
        {
            return true;
        }
        return false;
    }

    public function push(data:String)
    {
        buffer += data;
    }

    public function getMessage():String
    {
        final delimiterIndex = buffer.indexOf(delimiter);

        if (delimiterIndex != -1)
        {
            final message = buffer.substring(0, delimiterIndex);
            buffer = StringTools.replace(buffer, message + delimiter, "");

            return message;
        }
        return null;
    }

    public function handleData():String
    {
        return getMessage();
    }
}