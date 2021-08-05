package com.domwires.ext.service;

import com.domwires.core.mvc.model.AbstractModel;
import haxe.io.Error;

class AbstractService extends AbstractModel implements IService
{
    public var enabled(get, never):Bool;

    private var _enabled:Bool;

    @PostConstruct
    private function init():Void
    {
        throw Error.Custom("Override!");
    }

    private function initResult(success:Bool):Void
    {
        _enabled = success;

        if (_enabled == null) _enabled = true;

        if (_enabled)
        {
            initSuccess();
        } else
        {
            initFail();
        }
    }

    private function initSuccess():Void
    {
        trace("Initialized!");
    }

    private function initFail():Void
    {
        trace("Failed to initialize!");
    }

    private function get_enabled():Bool
    {
        return _enabled;
    }
}
