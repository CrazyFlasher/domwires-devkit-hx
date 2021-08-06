import massive.munit.Assert;

class TemplateMunitTest
{
    @BeforeClass
    public function beforeClass():Void
    {
    }

    @AfterClass
    public function afterClass():Void
    {
    }

    @Before
    public function setup():Void
    {
    }

    @After
    public function tearDown():Void
    {
    }


    @Test
    public function testTemplateTest():Void
    {
        Assert.isTrue(true);
    }
}
