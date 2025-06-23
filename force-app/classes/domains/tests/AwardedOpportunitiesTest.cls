@IsTest
public with sharing class AwardedOpportunitiesTest {

	@IsTest
	static void testOpportunityStageHasNotChangedToAwarded(){
		List<Opportunity> opportunities = TestDataFactory.createOpportunities(3,false,true);
		for (Opportunity opportunity:opportunities){
			opportunity.StageName = Utils.PLANNING_0; //Must use Utils instead on Opportunities to avoid getting "Variable does not exist: AWARDED" on Deployment (known issue for Abstract classes)
		}
		AwardedOpportunities newlyAwardedOpportunities = new AwardedOpportunities(opportunities);
		Assert.isTrue(newlyAwardedOpportunities.isEmpty());
	}

	@IsTest
	static void testOpportunityStageHasChangedToAwarded(){
		List<Opportunity> opportunities = TestDataFactory.createOpportunities(3,false,true);
		opportunities[0].StageName=Utils.AWARDED; //Must use Utils.AWARDED to avoid getting "Variable does not exist: AWARDED" on Deployment (known issue for Abstract classes)
		opportunities[2].StageName=Utils.AWARDED; //Must use Utils.AWARDED to avoid getting "Variable does not exist: AWARDED" on Deployment (known issue for Abstract classes)
		AwardedOpportunities newlyAwardedOpportunities = new AwardedOpportunities(opportunities);
		Assert.areEqual(
				2,
				newlyAwardedOpportunities.size(),
				'2 Opportunities should remain after filtering out awarded Opportunities');
	}

	@IsTest
	static void testOpportunityStageHasNewlyChangedToAwarded(){
		List<Opportunity> oldOpportunities = TestDataFactory.createOpportunities(3,false,true);
		for (Opportunity oldOpportunity:oldOpportunities){
			oldOpportunity.StageName = Opportunities.PLANNING_0;
		}
		List<Opportunity> newOpportunities = oldOpportunities.deepClone(true);
		newOpportunities[0].StageName=Opportunities.AWARDED;
		newOpportunities[2].StageName=Opportunities.AWARDED;
		AwardedOpportunities newlyAwardedOpportunities = new AwardedOpportunities(newOpportunities, oldOpportunities);
		Assert.areEqual(
				2,
				newlyAwardedOpportunities.size(),
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
				new Account(Name='NO Account', Navision_Customer_NO__c=true),
				new Account(Name='SE Account', Navision_Customer_SE__c=true)
		};
		insert parentAccounts;
		update new User(Id=UserInfo.getUserId(), Country='Sweden');
		for (Integer i=0 ; i< opportunities.size(); i++){
			opportunities[i].OwnerId=UserInfo.getUserId();
			opportunities[i].StageName=Utils.AWARDED;  //Must use Utils.AWARDED instead of Opportunities to avoid getting "Variable does not exist: AWARDED" on Deployment (known issue for Abstract classes)
			opportunities[i].AccountId=parentAccounts[i].Id;
		}

		AwardedOpportunities awardedOpportunities = new AwardedOpportunities(opportunities);
		System.debug(awardedOpportunities.getRecords());
		awardedOpportunities.filterByMatchingOwnerCountry();
		Assert.areEqual(1, awardedOpportunities.size(), '1 Awarded Opportunity Owner should match Navision Country');
		Assert.areEqual(opportunities[1].Id, awardedOpportunities.getRecords()[0].Id, 'Only 1 Awarded Opportunity Owner Matches Navision Country');
	}

	@IsTest
	static void shouldReturn1NewOpportunityWithNoContractInServiceNow(){
		List<Opportunity> opportunities = TestDataFactory.createOpportunities(2,false,true);
		opportunities[0].New_or_Renewal__c='New';
		opportunities[1].New_or_Renewal__c='New';
		opportunities[0].ContractServiceNowUrl__c='URL';
		opportunities[0].StageName=Utils.AWARDED;
		opportunities[1].StageName=Utils.AWARDED;
		AwardedOpportunities awardedOpportunities = new AwardedOpportunities(opportunities);
		awardedOpportunities.filterNewOpportunitiesWithoutContracts();
		Assert.areEqual(1, awardedOpportunities.size(), 'Only 1 New Opportunity should remain');
		Assert.areEqual(opportunities[1].Id, awardedOpportunities.getRecords()[0].Id,'Only the Opportunity without Contract ServiceNow URL should remain');
	}
}