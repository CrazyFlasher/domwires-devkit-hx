import utest.Runner;
import utest.ui.Report;

class Test
{
    public static function main()
    {
        var runner:Runner = new Runner();

        // runner.addCase(new typedeftest.ModelFromTypeDefTest());
        // runner.addCase(new com.domwires.ext.service.net.ClientServerServiceTest());
        runner.addCase(new com.domwires.ext.service.net.DataBaseServiceTest());

        Report.create(runner);
        runner.run();
    }
}
