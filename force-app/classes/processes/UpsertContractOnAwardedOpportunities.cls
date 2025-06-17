public with sharing class UpsertContractOnAwardedOpportunities implements TriggerAction.BeforeUpdate{
	@TestVisible
	private static Map<Id, Account> parentAccountsByIds;
	public void beforeUpdate(List<Opportunity> newOpportunities, List<Opportunity> oldOpportunities) {
		Logger.debug('UpsertContractOnAwardedOpportunities - Before Update');
		Logger.suspendSaving();
		Map<Id, Opportunity> oldOpportunitiesByIds = new Map<Id, Opportunity>(oldOpportunities);
		parentAccountsByIds = getAccountByIdsFromChildOpportunities(newOpportunities);

		for (Opportunity opportunity:newOpportunities){
			Opportunity newOpportunity=opportunity;
			Opportunity oldOpportunity=oldOpportunitiesByIds.get(newOpportunity.Id);

			if(!hasOpportunityStageChangedToAwarded(oldOpportunity, newOpportunity)){
				continue;
			}

			if(
				newOpportunity.New_Or_Renewal__c == 'New' &&
				String.isBlank(newOpportunity.ContractServiceNowUrl__c) &&
				doesOpportunityOwnerCountryMatchNavisionCustomerCountry(newOpportunity)
			){
				DML.enqueueJob(new ServiceNowUploadContractsQueueable(newOpportunity));
				Logger.info('Contract is created in ServiceNow for this Opportunity', newOpportunity).addTag('Opportunity trigger handler service');
				Logger.resumeSaving();
			} else {
				Logger.info('Contract is not created is ServiceNow for this Opportunity', newOpportunity).addTag('Opportunity trigger handler service');
				Logger.info('New or renewal: ' + newOpportunity.New_Or_Renewal__c).addTag('Opportunity trigger handler service');
				Logger.info('Service Now contract url: ' + newOpportunity.ContractServiceNowUrl__c).addTag('Opportunity trigger handler service');
				if (!doesOpportunityOwnerCountryMatchNavisionCustomerCountry(newOpportunity)) {
					Logger.error('Opportunity Owner Country: "'+opportunity.Owner_Country__c+'" does not match the Account\'s Country in Navision').addTag('Opportunity trigger handler service');
				}
				Logger.resumeSaving();
			}
		}
		Logger.saveLog();
	}

	public static Boolean hasOpportunityStageChangedToAwarded(Opportunity oldOpportunity, Opportunity newOpportunity){
		return (newOpportunity.StageName == Utils.AWARDED && newOpportunity.StageName != oldOpportunity.StageName);
	}

	public static Map<Id, Account> getAccountByIdsFromChildOpportunities(List<Opportunity> newOpportunities){
		Set<Id> accountIds = new Set<Id>();
		for (Opportunity opportunity:newOpportunities){
			accountIds.add(opportunity.AccountId);
		}
		return new Map<Id, Account>([SELECT Navision_Customer_NO__c, Navision_Customer_DK__c, Navision_Customer_SE__c FROM Account WHERE Id IN: accountIds]);
	}

	public static Boolean doesOpportunityOwnerCountryMatchNavisionCustomerCountry(Opportunity opportunity){
		Account parenAccount=parentAccountsByIds.get(opportunity.AccountId);
		return
				opportunity.Owner.Country=='Norway' && parenAccount.Navision_Customer_NO__c ||
				opportunity.Owner.Country=='Sweden' && parenAccount.Navision_Customer_SE__c ||
				opportunity.Owner.Country=='Denmark' && parenAccount.Navision_Customer_DK__c;
	}
}