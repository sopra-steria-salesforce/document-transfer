public with sharing class UpsertContractOnAwardedOpportunities implements TriggerAction.BeforeUpdate{

	public void beforeUpdate(List<Opportunity> newOpportunities, List<Opportunity> oldOpportunities) {
		Logger.debug('UpsertContractOnAwardedOpportunities - Before Update');

		AwardedOpportunities newlyAwardedOpportunities = new AwardedOpportunities(newOpportunities, oldOpportunities);
		newlyAwardedOpportunities.filterByMatchingOwnerCountry();
		newlyAwardedOpportunities.filterNewOpportunitiesWithoutContracts();
		if (!newlyAwardedOpportunities.isEmpty()) {
			new AwardedOpportunities(newlyAwardedOpportunities.getRecords()).upsertContractToServiceNow();
		}
	}
}