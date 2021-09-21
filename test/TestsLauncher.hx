import utest.Runner;
import utest.ui.Report;

class TestsLauncher
{
    public static function main()
    {
        #if nodejs
        untyped global.WebSocket = require("ws");
        #end

        var runner:Runner = new Runner();

//        runner.addCase(new typedeftest.ModelFromTypeDefTest());
//        runner.addCase(new com.domwires.ext.service.net.ClientServerServiceTest.ClientServerTest_NodeHttp_NodeSocket_NodeClient());
//        runner.addCase(new com.domwires.ext.service.net.ClientServerServiceTest.ClientServerTest_NodeHttp_WebSocket_WebSocketClient());
//        runner.addCase(new com.domwires.ext.service.net.ClientServerServiceTest.ClientServerTest_NodeHttp_NodeWebSocket_WebSocketClient());
//        runner.addCase(new com.domwires.ext.service.net.DataBaseServiceTest());
//        runner.addCase(new com.domwires.ext.service.net.AuthStackTest.AuthStackTest_NodeSocket_NodeMongoDb_NodeClient());
//        runner.addCase(new com.domwires.ext.service.net.AuthStackTest.AuthStackTest_WebSocket_NodeMongoDb_WebSocketClient());
//        runner.addCase(new com.domwires.ext.service.net.AuthStackTest.AuthStackTest_NodeWebSocket_NodeMongoDb_WebSocketClient());
//        runner.addCase(new com.domwires.ext.context.AppContextTest());
        runner.addCase(new com.domwires.ext.debug.DebugTest());

        Report.create(runner);
        runner.run();
    }
}
