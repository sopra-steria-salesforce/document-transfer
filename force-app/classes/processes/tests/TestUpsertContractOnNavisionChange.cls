@IsTest
public with sharing class TestUpsertContractOnNavisionChange {

	@IsTest
	static void navisionCustomerUpdatesShouldTriggerContractCreationForAwardedOpportunitiesWithNoContract(){
		DML.isMockDML=true;
		System.runAs(new User(Id=UserInfo.getUserId())) {
			TestingUtils.activateCustomPermission(UserInfo.getUserId(), 'ServiceNowContractUpsertTesting');
		}

		List<Opportunity> awardedOpportunities = TestDataFactory.createOpportunities(2, true,false);
		awardedOpportunities[0].StageName = Opportunities.AWARDED;
		awardedOpportunities[1].StageName = Opportunities.AWARDED;
		awardedOpportunities[0].New_or_Renewal__c='New';
		awardedOpportunities[1].New_or_Renewal__c='New';

		MetadataTriggerHandler.bypass('UpsertContractOnAwardedOpportunities');
		System.runAs(new User(Id=UserInfo.getUserId())){
			Assert.isTrue(FeatureManagement.checkPermission('ServiceNowContractUpsertTesting'),'ServiceNowContractUpsertTesting custom permission should be assigned');
			update awardedOpportunities;
		}
		update new User(
				Id=UserInfo.getUserId(),
				Country='Norway'
		);
		List<Account> oldAccounts = new List<Account>{
				new Account(Id=awardedOpportunities[0].AccountId),
				new Account(Id=awardedOpportunities[1].AccountId)
		};
		List<Account> newAccounts = new List<Account>{
				new Account(Id=awardedOpportunities[0].AccountId, Navision_Customer_NO__c=true),
				new Account(Id=awardedOpportunities[1].AccountId, Navision_Customer_SE__c=true)
		};
		Test.startTest();
		UpsertContractOnNavisionChange upsertContractOnNavisionChange = new UpsertContractOnNavisionChange();
		upsertContractOnNavisionChange.afterUpdate(newAccounts,oldAccounts);
		Test.stopTest();

		Assert.isFalse(DML.enqueuedJobs.isEmpty(),'1 Queueable job should be queued');
		Assert.isInstanceOfType(DML.enqueuedJobs[0],ServiceNowUploadContractsQueueable.class, 'ServiceNowUploadContractsQueueable should be queued');
	}

}