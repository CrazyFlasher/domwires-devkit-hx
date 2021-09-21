package com.domwires.ext.debug.mock;

import com.domwires.core.mvc.command.AbstractCommand;

@CommandAlias("test")
@CommandDesc("Test Command")
class MockCommand extends AbstractCommand
{
    @Inject("v")
    private var v:Int;

    @Inject("s")
    private var s:String;

    @Inject("o")
    private var o:Dynamic;

    @Inject
    private var model:IMockModel;

    override public function execute():Void
    {
        super.execute();

        model.setV(v);
        model.setS(s);
        model.setO(o);
    }
}
