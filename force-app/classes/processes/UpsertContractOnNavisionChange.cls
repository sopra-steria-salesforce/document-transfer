public with sharing class UpsertContractOnNavisionChange implements TriggerAction.AfterUpdate {
	public void afterUpdate(List<Account> newAccounts, List<Account> oldAccounts) {
		Logger.debug('UpsertContractOnNavisionChange - After Update');

		NavisionAccounts navisionAccountsWithCountryChange = new NavisionAccounts(newAccounts).filterAccountsWithNavisionCountryPositiveChange(oldAccounts);

		AwardedOpportunities awardedOpportunitiesWithNoContract = new AwardedOpportunities(
			[
				SELECT Id, AccountId, OwnerId, StageName, New_or_Renewal__c, ContractServiceNowUrl__c,
						Owner_Country__c, Account.Navision_Customer_NO__c,
						Account.Navision_Customer_SE__c, Account.Navision_Customer_DK__c,
						Contract_Category__c, Name, Contract_Lookup__c, Sub_Area__c
				FROM Opportunity
				WHERE StageName = :Opportunities.AWARDED
				AND IsContractSent__c=FALSE
				AND New_or_Renewal__c='New'
				AND AccountId IN :navisionAccountsWithCountryChange.getAccountIds()
			]
		);
		awardedOpportunitiesWithNoContract.parentAccountsByIds=new Map<Id, Account>(newAccounts);
		awardedOpportunitiesWithNoContract.filterByMatchingOwnerCountry();

		if (!awardedOpportunitiesWithNoContract.isEmpty()){
			if(Test.isRunningTest()) {
				awardedOpportunitiesWithNoContract.upsertContractToServiceNow();
			}
		}
	}
}