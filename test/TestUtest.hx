import utest.Runner;
import utest.ui.Report;

class TestUtest
{
    public static function main()
    {
        var runner:Runner = new Runner();
        // runner.addCases("com.domwires.ext");
        runner.addCase(new TemplateUtestTest());
        runner.addCase(new com.domwires.ext.service.net.impl.WebServerServiceTestUtest());

        Report.create(runner);
        runner.run();
    }
}
