@IsTest
public with sharing class AwardedOpportunitiesTest {

	@IsTest
	static void testOpportunityStageHasNotChangedToAwarded(){
		List<Opportunity> opportunities = TestDataFactory.createOpportunities(3,false,true);
		for (Opportunity opportunity:opportunities){
			opportunity.StageName = Utils.PLANNING_0;
		}
		AwardedOpportunities newlyAwardedOpportunities = new AwardedOpportunities(opportunities);
		Assert.isTrue(newlyAwardedOpportunities.awardedOpportunities.isEmpty());
	}

	@IsTest
	static void testOpportunityStageHasChangedToAwarded(){
		List<Opportunity> opportunities = TestDataFactory.createOpportunities(3,false,true);
		opportunities[0].StageName=Utils.AWARDED;
		opportunities[2].StageName=Utils.AWARDED;
		AwardedOpportunities newlyAwardedOpportunities = new AwardedOpportunities(opportunities);
		Assert.areEqual(
				2,
				newlyAwardedOpportunities.awardedOpportunities.size(),
				'2 Opportunities should remain after filtering out awarded Opportunities');
	}

	@IsTest
	static void testOpportunityStageHasNewlyChangedToAwarded(){
		List<Opportunity> oldOpportunities = TestDataFactory.createOpportunities(3,false,true);
		for (Opportunity oldOpportunity:oldOpportunities){
			oldOpportunity.StageName = Utils.PLANNING_0;
		}
		List<Opportunity> newOpportunities = oldOpportunities.deepClone(true);
		newOpportunities[0].StageName=Utils.AWARDED;
		newOpportunities[2].StageName=Utils.AWARDED;
		AwardedOpportunities newlyAwardedOpportunities = new AwardedOpportunities(newOpportunities, oldOpportunities);
		Assert.areEqual(
				2,
				newlyAwardedOpportunities.awardedOpportunities.size(),
				'2 Opportunities should remain after filtering out newly awarded Opportunities'
		);
	}
}