@IsTest
public with sharing class UpsertContractOnAwardedOpportunitiesTest {

	@IsTest
	static void testOpportunityStageHasNotChangedToAwarded(){
		Opportunity oldOpportunity = TestDataFactory.createOpportunities(1,false,true)[0];
		oldOpportunity.StageName = Utils.PLANNING_0;
		Opportunity newOpportunity = oldOpportunity.clone(true);
		Assert.isFalse(UpsertContractOnAwardedOpportunities.hasOpportunityStageChangedToAwarded(oldOpportunity, newOpportunity));
	}

	@IsTest
	static void testOpportunityStageHasChangedToAwarded(){
		Opportunity oldOpportunity = TestDataFactory.createOpportunities(1,false,true)[0];
		oldOpportunity.StageName = Utils.PLANNING_0;
		Opportunity newOpportunity = oldOpportunity.clone(true);
		newOpportunity.StageName=Utils.AWARDED;
		Assert.isTrue(UpsertContractOnAwardedOpportunities.hasOpportunityStageChangedToAwarded(oldOpportunity, newOpportunity));
	}

	@IsTest
	static void testOpportunityOwnerCountryMatchesNavisionCustomerCountry(){
		Opportunity oldOpportunity = TestDataFactory.createOpportunities(1,false,true)[0];
		oldOpportunity.Navision_Customer_NO__c=true;
		User u = new User(
				Id=UserInfo.getUserId(),
				Country='Norway'
		);
		oldOpportunity.Owner=u;
		Opportunity newOpportunity = oldOpportunity.clone(true);
		Formula.recalculateFormulas(new List<Opportunity>{newOpportunity});
		Assert.isTrue(newOpportunity.Navision_Account_in_Owners_Country__c);
		Assert.isTrue(UpsertContractOnAwardedOpportunities.doesOpportunityOwnerCountryMatchNavisionCustomerCountry(oldOpportunity,newOpportunity));
	}

	@IsTest
	static void testOpportunityOwnerCountryDoesNotMatchNavisionCustomerCountry(){
		Opportunity oldOpportunity = TestDataFactory.createOpportunities(1,false,true)[0];
		oldOpportunity.Navision_Customer_NO__c=true;
		User u = new User(
				Id=UserInfo.getUserId(),
				Country='Sweden'
		);
		oldOpportunity.Owner=u;
		Opportunity newOpportunity = oldOpportunity.clone(true);
		Formula.recalculateFormulas(new List<Opportunity>{newOpportunity});
		Assert.isTrue(newOpportunity.Navision_Account_in_Owners_Country__c);
		Assert.isTrue(UpsertContractOnAwardedOpportunities.doesOpportunityOwnerCountryMatchNavisionCustomerCountry(oldOpportunity,newOpportunity));
	}
}