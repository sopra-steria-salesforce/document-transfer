public with sharing class NavisionAccounts {

	private List<Account> accounts;

	public NavisionAccounts(List<Account> accounts) {
		this.accounts = new List<Account>();
		for (Account account : accounts) {
			if (
					account.Navision_Customer_NO__c == true ||
					account.Navision_Customer_SE__c == true ||
					account.Navision_Customer_DK__c == true
			) {
				this.accounts.add(account);
			}
		}
	}

	public List<Account> getAccounts() {
		return this.accounts;
	}

	public NavisionAccounts filterAccountsWithNavisionCountryPositiveChange(List<Account> oldAccounts) {
		Map<Id, Account> oldAccountsById = new Map<Id, Account>(oldAccounts);
		List<Account> filteredAccounts = new List<Account>();

		for (Account newAccount : accounts) {
			Account oldAccount = oldAccountsById.get(newAccount.Id);
			if (oldAccount == null) continue;

			if (
					(newAccount.Navision_Customer_NO__c == true && oldAccount.Navision_Customer_NO__c != true) ||
					(newAccount.Navision_Customer_SE__c == true && oldAccount.Navision_Customer_SE__c != true) ||
					(newAccount.Navision_Customer_DK__c == true && oldAccount.Navision_Customer_DK__c != true)
			) {
				filteredAccounts.add(newAccount);
			}
		}

		return new NavisionAccounts(filteredAccounts);
	}
	public Set<Id> getAccountIds() {
		return new Map<Id, Account>(this.accounts).keySet();
	}
}