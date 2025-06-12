@IsTest
public inherited sharing class AwardedOpportunitiesTest {
    @IsTest
    static void testOpportunityStageHasNotChangedToAwarded(){
        List<Opportunity> oldOpportunities = TestDataFactory.createOpportunities(3,false,true);
        for (Opportunity oldOpportunity:oldOpportunities){
            oldOpportunity.StageName = Utils.PLANNING_0;
        }
        List<Opportunity> newOpportunities = oldOpportunities.deepClone();
        AwardedOpportunities newlyAwardedOpportunities = AwardedOpportunities.getOpportunitiesThatChangedToAwarded(oldOpportunities, newOpportunities);
        Assert.isTrue(newlyAwardedOpportunities.awardedOpportunities.isEmpty());
    }

    @IsTest
    static void testOpportunityStageHasChangedToAwarded(){
        List<Opportunity> oldOpportunities = TestDataFactory.createOpportunities(3,false,true);
        for (Opportunity oldOpportunity:oldOpportunities){
            oldOpportunity.StageName = Utils.PLANNING_0;
        }
        List<Opportunity> newOpportunities = oldOpportunities.deepClone();
        newOpportunities[0].StageName=Utils.AWARDED;
        newOpportunities[2].StageName=Utils.AWARDED;
        AwardedOpportunities newlyAwardedOpportunities = AwardedOpportunities.getOpportunitiesThatChangedToAwarded(oldOpportunities, newOpportunities);
        Assert.areEqual(
                2,
                newlyAwardedOpportunities.awardedOpportunities.size(),
                '2 Opportunities should remain after filtering out newly awarded Opportunities'
        );
    }
}
