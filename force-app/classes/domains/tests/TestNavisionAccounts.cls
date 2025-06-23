@IsTest
public with sharing class TestNavisionAccounts {

	@IsTest
	static void shouldReturnAccountswithPositiveNavisionChange(){
		List<Account> oldAccounts = TestDataFactory.createAccounts(4, false, true);
		List<Account> newAccounts = oldAccounts.deepClone(true);
		newAccounts[0].Navision_Customer_NO__c=true;

		Assert.areEqual(1, new NavisionAccounts(newAccounts).filterAccountsWithNavisionCountryPositiveChange(oldAccounts).getAccounts().size(), 'One Account should remain after filtering');
		Assert.areEqual(newAccounts[0].Id,new NavisionAccounts(newAccounts).filterAccountsWithNavisionCountryPositiveChange(oldAccounts).getAccounts()[0].Id, 'Only the first Account should remain after filtering');

		oldAccounts[1].Navision_Customer_SE__c=true;
		Assert.areEqual(1,new NavisionAccounts(newAccounts).filterAccountsWithNavisionCountryPositiveChange(oldAccounts).getAccounts().size(), 'Only Account with Navision Change from False to True should remain after filtering');
		Assert.areEqual(newAccounts[0].Id,new NavisionAccounts(newAccounts).filterAccountsWithNavisionCountryPositiveChange(oldAccounts).getAccounts()[0].Id, 'Only the first Account should remain after filtering');
	}
}