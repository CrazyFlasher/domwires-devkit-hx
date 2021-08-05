import TemplateTest;
import com.domwires.ext.service.net.impl.WebServerServiceTest;
import massive.munit.TestSuite;

/**
 * Auto generated Test Suite for MassiveUnit.
 * Refer to munit command line tool for more information (haxelib run munit)
 */
class TestSuite extends massive.munit.TestSuite
{
	public function new()
	{
		super();

		add(com.domwires.ext.service.net.impl.WebServerServiceTest);
		add(TemplateTest);
	}
}
