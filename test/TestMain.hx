import massive.munit.Assert;
import massive.munit.TestRunner;
import massive.munit.client.RichPrintClient;

class TestMain
{
    static function main()
    {
        var client = new RichPrintClient();
        var runner = new TestRunner(client);
        runner.run([TestSuite]);
    }
}
