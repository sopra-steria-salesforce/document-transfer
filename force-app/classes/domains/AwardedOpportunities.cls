public inherited sharing class AwardedOpportunities {
    public List<Opportunity> awardedOpportunities;

    public AwardedOpportunities(List<Opportunity> opportunities) {
        List<Opportunity> awardedOpportunities = new List<Opportunity>();
        for (Opportunity opportunity : opportunities) {
            if (opportunity.StageName == Utils.AWARDED) {
                awardedOpportunities.add(opportunity);
            }
        }
        this.awardedOpportunities=awardedOpportunities;
    }

    public static AwardedOpportunities getOpportunitiesThatChangedToAwarded(List<Opportunity> oldOpportunities, List<Opportunity> newOpportunities) {
        List<Opportunity> opportunitiesThatChangedToAwarded = (List<Opportunity>) UtilityService.getRecordsWithChangedFieldValue(oldOpportunities, newOpportunities, 'StageName', Utils.AWARDED);
        return new AwardedOpportunities(opportunitiesThatChangedToAwarded);
    }
}
