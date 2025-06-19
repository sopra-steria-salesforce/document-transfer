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

	@IsTest
	static void testOpportunityOwnerCountryMatchesNavisionCustomerCountry(){
		List<Opportunity> opportunities = TestDataFactory.createOpportunities(2,false,true);
		AwardedOpportunities awardedOpportunities = new AwardedOpportunities(opportunities);
		Assert.isTrue(awardedOpportunities.doesOpportunityOwnerCountryMatchNavisionCustomerCountry(
				new Account(Navision_Customer_NO__c=true),
				new User(Country='Norway')
		),
				'Norwegian Opportunity should match Norwegian Account');
		Assert.isFalse(awardedOpportunities.doesOpportunityOwnerCountryMatchNavisionCustomerCountry(
				new Account(Navision_Customer_NO__c=true),
				new User(Country='Sweden')
		),
				'Swedish Opportunity should not match Norwegian Account');
	}

	@IsTest
	static void filterByMatchingOwnerCountry(){
		List<Opportunity> opportunities = TestDataFactory.createOpportunities(2,false,true);
		List<Account> parentAccounts = new List<Account>{
				new Account(Navision_Customer_NO__c=true),
				new Account(Navision_Customer_SE__c=true)
		};
		insert parentAccounts;
		update new User(UserInfo.getUserId(), Country='Sweden');
		for (Integer i; i< opportunities.size(); i++){
			opportunities[i].OwnerId=UserInfo.getUserId();
			opportunities[i].StageName=Opportunities.AWARDED;
			opportunities[i].AccountId=parentAccounts[i].Id;
		}

		AwardedOpportunities awardedOpportunities = new AwardedOpportunities(opportunities);
		awardedOpportunities.filterByMatchingOwnerCountry();
		Assert.areEqual(1, awardedOpportunities.getRecords().size(), 'Only 1 Awarded Opportunity Owner Matches Navision Country');
		Assert.areEqual(opportunities[0].Id, awardedOpportunities.getRecords()[0].Id, 'Only 1 Awarded Opportunity Owner Matches Navision Country');
	}
}