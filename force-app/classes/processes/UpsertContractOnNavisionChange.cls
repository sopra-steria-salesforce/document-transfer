public with sharing class UpsertContractOnNavisionChange implements TriggerAction.AfterUpdate {
	public void afterUpdate(List<Account> newAccounts, List<Account> oldAccounts) {
		Logger.debug('UpsertContractOnNavisionChange - After Update');

		NavisionAccounts navisionAccountsWithCountryChange = new NavisionAccounts(newAccounts).filterAccountsWithNavisionCountryPositiveChange(oldAccounts);
		if (navisionAccountsWithCountryChange.getAccounts().isEmpty()) return;

		List<Opportunity> awardedOpportunities = [
				SELECT Id, AccountId, OwnerId, StageName, New_or_Renewal__c, ContractServiceNowUrl__c,
						Owner.Country, Account.Navision_Customer_NO__c,
						Account.Navision_Customer_SE__c,
						Account.Navision_Customer_DK__c
				FROM Opportunity
				WHERE StageName = :Opportunities.AWARDED
				AND AccountId IN :navisionAccountsWithCountryChange.getAccountIds()
		];
		if (awardedOpportunities.isEmpty()) return;

		new AwardedOpportunities(awardedOpportunities)
				.filterByMatchingOwnerCountry()
				.filterNewOpportunitiesWithoutContracts()
				.upsertContractToServiceNow();
	}
}