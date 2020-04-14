@isTest
public class UtilTests
{
	@testvisible private static Boolean crashTest = true;

	public static testMethod void test1()
	{
		for (Account a: [SELECT Id, Name FROM Account])
		{
			System.debug(a);
		}

		System.assert(!crashTest, 'Crash Test is on.');
	}
}
