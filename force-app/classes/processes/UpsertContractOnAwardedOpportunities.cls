public with sharing class UpsertContractOnAwardedOpportunities implements TriggerAction.BeforeUpdate{

	public void beforeUpdate(List<Opportunity> newOpportunities, List<Opportunity> oldOpportunities) {
		Logger.debug('UpsertContractOnAwardedOpportunities - Before Update');
		Logger.suspendSaving();

		AwardedOpportunities newlyAwardedOpportunities = new AwardedOpportunities(newOpportunities, oldOpportunities);
		newlyAwardedOpportunities.filterByMatchingOwnerCountry();
		if (!newlyAwardedOpportunities.isEmpty()) {
			upsertContractOnNewAwardedOpportunities(newlyAwardedOpportunities);
		}
	}

	public static void upsertContractOnNewAwardedOpportunities(AwardedOpportunities awardedOpportunities){
		for (Opportunity opportunity:awardedOpportunities.awardedOpportunities){
			if(
					opportunity.New_Or_Renewal__c == 'New' &&
					String.isBlank(opportunity.ContractServiceNowUrl__c)
			){
				DML.enqueueJob(new ServiceNowUploadContractsQueueable(opportunity));
				Logger.info('Contract is created in ServiceNow for this Opportunity', opportunity).addTag('Opportunity trigger handler service');
				Logger.resumeSaving();
			} else {
				Logger.info('Contract is not created is ServiceNow for this Opportunity', opportunity).addTag('Opportunity trigger handler service');
				Logger.info('New or renewal: ' + opportunity.New_Or_Renewal__c).addTag('Opportunity trigger handler service');
				Logger.info('Service Now contract url: ' + opportunity.ContractServiceNowUrl__c).addTag('Opportunity trigger handler service');
				Logger.resumeSaving();
			}
		}
		Logger.saveLog();
		Logger.resumeSaving();
	}
}