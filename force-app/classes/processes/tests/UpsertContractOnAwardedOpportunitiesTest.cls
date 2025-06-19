@IsTest
public with sharing class UpsertContractOnAwardedOpportunitiesTest {

	@IsTest
	static void mockedOpportunityShouldEnqueueServiceNowUploadContractsQueueableWhenNewlyAwardedOpportunityOwnerMatchesNavisionCustomerCountry(){
		DML.isMockDML=true;
		List<Opportunity> oldOpportunities = TestDataFactory.createOpportunities(2,false,true);
		List<Account> parentAccounts = new List<Account>{
				new Account(Name='NO Account', Navision_Customer_NO__c=true),
				new Account(Name='SE Account', Navision_Customer_SE__c=true)
		};
		insert parentAccounts;
		update new User(Id=UserInfo.getUserId(), Country='Sweden');
		for (Integer i=0 ; i< oldOpportunities.size(); i++){
			oldOpportunities[i].OwnerId=UserInfo.getUserId();
			oldOpportunities[i].New_or_Renewal__c='New';
			oldOpportunities[i].AccountId=parentAccounts[i].Id;
		}

		List<Opportunity> newOpportunities = oldOpportunities.deepClone(true);
		newOpportunities[0].StageName=Opportunities.AWARDED;
		newOpportunities[1].StageName=Opportunities.AWARDED;
		UpsertContractOnAwardedOpportunities testUpsertContractOnAwardedOpportunities = new UpsertContractOnAwardedOpportunities();

		Test.startTest();
		testUpsertContractOnAwardedOpportunities.beforeUpdate(newOpportunities, oldOpportunities);
		Test.stopTest();

		Assert.isFalse(DML.enqueuedJobs.isEmpty(),'1 Queueable job should be queued');
		Assert.isInstanceOfType(DML.enqueuedJobs[0],ServiceNowUploadContractsQueueable.class, 'ServiceNowUploadContractsQueueable should be queued');
	}

	@IsTest
	static void testNoOpportunityShouldEnqueueServiceNowUploadContractsQueueable(){
		DML.isMockDML=true;
		List<Opportunity> oldOpportunities = TestDataFactory.createOpportunities(2,false,true);
		List<Account> parentAccounts = new List<Account>{
				new Account(Name='NO Account', Navision_Customer_NO__c=true),
				new Account(Name='SE Account', Navision_Customer_SE__c=true)
		};
		insert parentAccounts;
		update new User(Id=UserInfo.getUserId(), Country='Denmark');
		for (Integer i=0 ; i< oldOpportunities.size(); i++){
			oldOpportunities[i].OwnerId=UserInfo.getUserId();
			oldOpportunities[i].New_or_Renewal__c='New';
			oldOpportunities[i].AccountId=parentAccounts[i].Id;
		}

		List<Opportunity> newOpportunities = oldOpportunities.deepClone(true);
		newOpportunities[0].StageName=Opportunities.PLANNING_0;
		newOpportunities[1].StageName=Opportunities.PLANNING_0;
		UpsertContractOnAwardedOpportunities testUpsertContractOnAwardedOpportunities = new UpsertContractOnAwardedOpportunities();

		Test.startTest();
		testUpsertContractOnAwardedOpportunities.beforeUpdate(newOpportunities, oldOpportunities);
		Test.stopTest();

		Assert.isTrue(DML.enqueuedJobs.isEmpty(),'No Queueable job should be queued');
	}
}