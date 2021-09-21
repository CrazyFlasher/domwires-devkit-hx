package com.domwires.ext.utils;

import haxe.Resource;
import json2object.JsonParser;
import com.domwires.core.mvc.context.IContext;

@:keep @:generic
class Debug
{
    private static var contextMap:Map<String, IContext> = [];

    private static var commandMap:CommandListData;

    @:expose
    public static function cmd(commandAlias:String, params:Dynamic, contextId:String):Void
    {
        if (!contextMap.exists(contextId))
        {
            trace("Context with id '" + contextId + "' is not mapped. Map context using 'Debug.mapContext'");

            return;
        }

        if (commandMap == null)
        {
            trace(Resource.getString("command_map.json"));

            commandMap = new JsonParser<CommandListData>().fromJson(Resource.getString("command_map.json"));
        }

        if (!commandMap.exists(commandAlias))
        {
            trace("Command '" + commandAlias + "' is missing in command_map.json!");

            return;
        }

        trace("Executing command " + commandAlias + " in context " + contextId);

        contextMap.get(contextId).executeCommand(cast Type.resolveClass(commandMap.get(commandAlias).className), params);
    }

    public static function mapContext(id:String, context:IContext):Void
    {
        contextMap.set(id, context);
    }
}

typedef CommandListData = Map<String, {
    final alias:String;
    final ?desc:String;
    final className:String;
}>