public with sharing class UpsertContractOnAwardedOpportunities implements TriggerAction.AfterUpdate{

	public void afterUpdate(List<Opportunity> newOpportunities, List<Opportunity> oldOpportunities) {
		Logger.debug('UpsertContractOnAwardedOpportunities - After Update');

		AwardedOpportunities newlyAwardedOpportunities = new AwardedOpportunities(newOpportunities, oldOpportunities);
		newlyAwardedOpportunities.filterByMatchingOwnerCountry();
		newlyAwardedOpportunities.getNewOpportunitiesWithNoContractInServiceNow();
		if (!newlyAwardedOpportunities.isEmpty()) {
			new AwardedOpportunities(newlyAwardedOpportunities.getRecords()).upsertContractToServiceNow();
		}
	}
}