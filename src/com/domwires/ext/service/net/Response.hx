package com.domwires.ext.service.net;

import com.domwires.ext.service.net.Request;

typedef Response =
{
    > Request,

    final data:String;
}