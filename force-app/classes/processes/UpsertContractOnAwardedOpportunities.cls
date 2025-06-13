public with sharing class UpsertContractOnAwardedOpportunities implements TriggerAction.BeforeUpdate{

	public void beforeUpdate(List<Opportunity> newOpportunities, List<Opportunity> oldOpportunities) {
		Logger.debug('UpsertContractOnAwardedOpportunities - Before Update');
		Map<Id, Opportunity> oldOpportunitiesByIds = new Map<Id, Opportunity>(oldOpportunities);
		for (Opportunity opportunity:newOpportunities){
			Opportunity newOpportunity=opportunity;
			Opportunity oldOpportunity=oldOpportunitiesByIds.get(newOpportunity.Id);

			if(!hasOpportunityStageChangedToAwarded(oldOpportunity, newOpportunity)){
				continue;
			}

			if(
				newOpportunity.New_Or_Renewal__c == 'New' &&
				String.isBlank(newOpportunity.ContractServiceNowUrl__c) &&
				doesOpportunityOwnerCountryMatchNavisionCustomerCountry(oldOpportunity, newOpportunity)
			){
				System.enqueueJob(new ServiceNowUploadContractsQueueable(newOpportunity));
				Logger.info('Contract is created in ServiceNow for this Opportunity', newOpportunity).addTag('Opportunity trigger handler service');
			} else {
				Logger.info('Contract is not created is ServiceNow for this Opportunity', newOpportunity).addTag('Opportunity trigger handler service');
				Logger.info('New or renewal: ' + newOpportunity.New_Or_Renewal__c).addTag('Opportunity trigger handler service');
				Logger.info('Service Now contract url: ' + newOpportunity.ContractServiceNowUrl__c).addTag('Opportunity trigger handler service');
			}
		}
		Logger.saveLog();
	}

	public static Boolean hasOpportunityStageChangedToAwarded(Opportunity oldOpportunity, Opportunity newOpportunity){
		return (newOpportunity.StageName == Utils.AWARDED && newOpportunity.StageName != oldOpportunity.StageName);
	}

	public static Boolean doesOpportunityOwnerCountryMatchNavisionCustomerCountry(Opportunity oldOpportunity, Opportunity newOpportunity){
		Boolean hasNavisionCustomerChanged =
				(newOpportunity.Navision_Customer_NO__c != oldOpportunity.Navision_Customer_NO__c) ||
						(newOpportunity.Navision_Customer_SE__c != oldOpportunity.Navision_Customer_SE__c) ||
						(newOpportunity.Navision_Customer_DK__c != oldOpportunity.Navision_Customer_DK__c);
		Logger.debug('hasNavisionCustomerChanged: ' + hasNavisionCustomerChanged, newOpportunity).addTag('Opportunity trigger handler service');

		Boolean doesOwnerCountryMatchCountryInNavision =
				(newOpportunity.Owner_Country__c == 'Norway' && newOpportunity.Navision_Customer_NO__c) ||
						(newOpportunity.Owner_Country__c == 'Sweden' && newOpportunity.Navision_Customer_SE__c) ||
						(newOpportunity.Owner_Country__c == 'Denmark' && newOpportunity.Navision_Customer_DK__c);
		Logger.debug('doesOwnerCountryMatchCountryInNavision: ' + doesOwnerCountryMatchCountryInNavision, newOpportunity).addTag('Opportunity trigger handler service');
		Logger.debug('Navision_Account_in_Owners_Country__c value on opportunity: ' + newOpportunity.Navision_Account_in_Owners_Country__c.toString(), newOpportunity).addTag('Opportunity trigger handler service');

		if (newOpportunity.Navision_Account_in_Owners_Country__c!=doesOwnerCountryMatchCountryInNavision) {
			Logger.warn('Navision_Account_in_Owners_Country__c does not match doesOwnerCountryMatchCountryInNavision!',newOpportunity).addTag('Opportunity trigger handler service');
			Formula.recalculateFormulas(new List<Opportunity>{newOpportunity});
			Logger.debug('Navision_Account_in_Owners_Country__c after Formula recalculation: ' +newOpportunity.Navision_Account_in_Owners_Country__c, newOpportunity).addTag('Opportunity trigger handler service');
		}

		return newOpportunity.Navision_Account_in_Owners_Country__c ||
				(doesOwnerCountryMatchCountryInNavision &&
						hasNavisionCustomerChanged);
	}
}