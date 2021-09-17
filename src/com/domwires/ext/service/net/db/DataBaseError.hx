package com.domwires.ext.service.net.db;

typedef DataBaseError = {
    code:Int,
    errmsg:String,
    message:String,
    stack:String
}

enum abstract DataBaseErrorCode(Int)
{
    var Duplicate = 11000;
}
