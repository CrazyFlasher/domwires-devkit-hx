package com.domwires.ext;

enum Error
{
    Override(?message:String);
    NotImplemented(?message:String);
    Custom(message:String);
}