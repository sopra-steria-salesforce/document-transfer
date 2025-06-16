public with sharing class UpsertContractOnAwardedOpportunities implements TriggerAction.BeforeUpdate{

	public void beforeUpdate(List<Opportunity> newOpportunities, List<Opportunity> oldOpportunities) {
		Logger.debug('UpsertContractOnAwardedOpportunities - Before Update');
		Map<Id, Opportunity> oldOpportunitiesByIds = new Map<Id, Opportunity>(oldOpportunities);
		Formula.recalculateFormulas(newOpportunities); // To ensure that Navision_Account_in_Owners_Country__c is up to date
		for (Opportunity opportunity:newOpportunities){
			Opportunity newOpportunity=opportunity;
			Opportunity oldOpportunity=oldOpportunitiesByIds.get(newOpportunity.Id);

			if(!hasOpportunityStageChangedToAwarded(oldOpportunity, newOpportunity)){
				continue;
			}

			if(
				newOpportunity.New_Or_Renewal__c == 'New' &&
				String.isBlank(newOpportunity.ContractServiceNowUrl__c) &&
				newOpportunity.Navision_Account_in_Owners_Country__c
			){
				System.enqueueJob(new ServiceNowUploadContractsQueueable(newOpportunity));
				Logger.info('Contract is created in ServiceNow for this Opportunity', newOpportunity).addTag('Opportunity trigger handler service');
			} else {
				Logger.info('Contract is not created is ServiceNow for this Opportunity', newOpportunity).addTag('Opportunity trigger handler service');
				Logger.info('New or renewal: ' + newOpportunity.New_Or_Renewal__c).addTag('Opportunity trigger handler service');
				Logger.info('Service Now contract url: ' + newOpportunity.ContractServiceNowUrl__c).addTag('Opportunity trigger handler service');
				if (!newOpportunity.Navision_Account_in_Owners_Country__c) {
					Logger.error('Opportunity Owner Country: "'+opportunity.Owner_Country__c+'" does not match the Account\'s Country in Navision').addTag('Opportunity trigger handler service');
				}

			}
		}
		Logger.saveLog();
	}

	public static Boolean hasOpportunityStageChangedToAwarded(Opportunity oldOpportunity, Opportunity newOpportunity){
		return (newOpportunity.StageName == Utils.AWARDED && newOpportunity.StageName != oldOpportunity.StageName);
	}
}