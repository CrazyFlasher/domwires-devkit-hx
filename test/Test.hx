import utest.Runner;
import utest.ui.Report;

class Test
{
    public static function main()
    {
        var runner:Runner = new Runner();
        // runner.addCases("com.domwires.ext");
        runner.addCase(new TemplateTest());
        runner.addCase(new com.domwires.ext.service.net.impl.WebServerServiceTest());

        Report.create(runner);
        runner.run();
    }
}
