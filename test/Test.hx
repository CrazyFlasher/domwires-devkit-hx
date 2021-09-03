import utest.Runner;
import utest.ui.Report;

class Test
{
    public static function main()
    {
        var runner:Runner = new Runner();

        // runner.addCases("com.domwires.ext");
        runner.addCase(new com.domwires.ext.service.net.ClientServerServiceTest());
        runner.addCase(new typedeftest.ModelFromTypeDefTest());

        Report.create(runner);
        runner.run();
    }
}
