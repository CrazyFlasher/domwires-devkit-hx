package com.domwires.ext.service;

import com.domwires.core.mvc.model.IModelImmutable;

interface IServiceImmutable extends IModelImmutable
{
    var enabled(get, never):Bool;
}
