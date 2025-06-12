public inherited sharing class AwardedOpportunities{

	public List<Opportunity> awardedOpportunities;

	public AwardedOpportunities(List<Opportunity> opportunities) {
		for (Opportunity opportunity:opportunities){
			if (opportunity.StageName==Utils.AWARDED) {
				awardedOpportunities.add(opportunity);
			}
		}
	}

	public static AwardedOpportunities getOpportunitiesThatChangedToAwarded (List<Opportunity>oldOpportunities, List<Opportunity> newOpportunities){
		List<Opportunity> opportunitiesThatChangedToAwarded = (List<Opportunity>) UtilityService.getRecordsWithChangedField(oldOpportunities, newOpportunities, 'StageName', Utils.AWARDED);
		return new AwardedOpportunities(opportunitiesThatChangedToAwarded);
	}
}