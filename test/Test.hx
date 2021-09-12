import utest.Runner;
import utest.ui.Report;

class Test
{
    public static function main()
    {
        #if js
        untyped global.WebSocket = require("ws");
        #end
        
        var runner:Runner = new Runner();

        runner.addCase(new typedeftest.ModelFromTypeDefTest());
        runner.addCase(new com.domwires.ext.service.net.ClientServerServiceTest());
        runner.addCase(new com.domwires.ext.service.net.DataBaseServiceTest());
        runner.addCase(new com.domwires.ext.service.net.AuthStackTest());

        Report.create(runner);
        runner.run();
    }
}
