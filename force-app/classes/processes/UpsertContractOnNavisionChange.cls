public with sharing class UpsertContractOnNavisionChange implements TriggerAction.AfterUpdate {
	public void afterUpdate(List<Account> newAccounts, List<Account> oldAccounts) {
		Logger.debug('UpsertContractOnNavisionChange - After Update');

		NavisionAccounts navisionAccountsWithCountryChange = new NavisionAccounts(newAccounts).filterAccountsWithNavisionCountryPositiveChange(oldAccounts);
		if (navisionAccountsWithCountryChange.getAccounts().isEmpty()) return;

		AwardedOpportunities awardedOpportunitiesWithNoContract = new AwardedOpportunities(
			[
				SELECT Id, AccountId, OwnerId, StageName, New_or_Renewal__c, ContractServiceNowUrl__c,
						Owner_Country__c, Account.Navision_Customer_NO__c,
						Account.Navision_Customer_SE__c,
						Account.Navision_Customer_DK__c
				FROM Opportunity
				WHERE StageName = :Opportunities.AWARDED
				AND IsContractSent__c=FALSE
				AND AccountId IN :navisionAccountsWithCountryChange.getAccountIds()
			]
		);
		if (awardedOpportunitiesWithNoContract.isEmpty()) return;

		awardedOpportunitiesWithNoContract.parentAccountsByIds=new Map<Id, Account>(newAccounts);
		awardedOpportunitiesWithNoContract
				.filterByMatchingOwnerCountry()
				.filterNewOpportunitiesWithoutContracts();

		if (!awardedOpportunitiesWithNoContract.isEmpty()){
			awardedOpportunitiesWithNoContract.upsertContractToServiceNow();
		}
	}
}