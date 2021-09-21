package com.domwires.ext.debug.mock;

import com.domwires.core.mvc.model.IModel;
import com.domwires.core.mvc.model.IModelImmutable;
import com.domwires.core.mvc.model.AbstractModel;

class MockModel extends AbstractModel implements IMockModel
{
    private var v:Int;
    private var s:String;
    private var o:Dynamic;

    public function setV(value:Int):Void
    {
        v = value;
    }

    public function setS(value:String):Void
    {
        s = value;
    }

    public function setO(value:Dynamic):Void
    {
        o = value;
    }

    public function getV():Int
    {
        return v;
    }

    public function getS():String
    {
        return s;
    }

    public function getO():Dynamic
    {
        return o;
    }
}

interface IMockModel extends IMockModelImmutable extends IModel
{
    function setV(value:Int):Void;
    function setS(value:String):Void;
    function setO(value:Dynamic):Void;
}

interface IMockModelImmutable extends IModelImmutable
{
    function getV():Int;
    function getS():String;
    function getO():Dynamic;
}