@IsTest
public with sharing class TestUpsertContractOnNavisionChange {

	@TestSetup
	static void setup(){
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
	}
	@IsTest
	static void mockedNavisionCustomerUpdatesShouldTriggerContractCreationForAwardedOpportunitiesWithNoContract(){
		DML.isMockDML=true;
		List<Opportunity> awardedOpportunities = [SELECT Id, AccountId FROM Opportunity];

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

	@IsTest
	static void navisionCustomerUpdatesShouldTriggerContractCreationForAwardedOpportunitiesWithNoContract(){
		TestingUtils.setJSONSuccessfulRequest('upsertContractResponse');

		List<Opportunity> awardedOpportunities = [SELECT Id, AccountId FROM Opportunity];

		Test.startTest();
		update new List<Account>{
				new Account(Id=awardedOpportunities[0].AccountId, Navision_Customer_NO__c=true),
				new Account(Id=awardedOpportunities[1].AccountId, Navision_Customer_SE__c=true)
		};
		Test.stopTest();

		Assert.isTrue([SELECT IsContractSent__c FROM Opportunity WHERE Id=:awardedOpportunities[0].Id].IsContractSent__c,'Contract for Norwegian Account should be upserted');
		Assert.isFalse([SELECT IsContractSent__c FROM Opportunity WHERE Id=:awardedOpportunities[1].Id].IsContractSent__c,'Contract for Swedish Account should not be upserted');
	}

	@IsTest
	static void navisionCustomerUpdatesShouldTriggerCallOffContractCreation(){
		TestingUtils.setJSONSuccessfulRequest('upsertCallOffContractsresponse');

		Contract_Archive__c testContractArchive = new Contract_Archive__c(Name = 'Test Contract Archive', Sys_Id_External__c = 'TestTaskSysId');
		insert testContractArchive;

		List<Opportunity> awardedOpportunities = [SELECT Id, AccountId, Contract_Category__c FROM Opportunity];
		awardedOpportunities[0].Contract_Category__c='New call off (Agreement on existing contract)';
		awardedOpportunities[1].Contract_Category__c='New call off (Agreement on existing contract)';
		awardedOpportunities[0].Type='Project';
		awardedOpportunities[1].Type='Project';
		awardedOpportunities[0].Contract_Lookup__c=testContractArchive.Id;
		awardedOpportunities[1].Contract_Lookup__c=testContractArchive.Id;
		update awardedOpportunities;

		Test.startTest();
		update new List<Account>{
				new Account(Id=awardedOpportunities[0].AccountId, Navision_Customer_NO__c=true),
				new Account(Id=awardedOpportunities[1].AccountId, Navision_Customer_SE__c=true)
		};
		Test.stopTest();

		Assert.isTrue([SELECT IsContractSent__c FROM Opportunity WHERE Id=:awardedOpportunities[0].Id].IsContractSent__c,'Contract for Norwegian Account should be upserted');
		Assert.isFalse([SELECT IsContractSent__c FROM Opportunity WHERE Id=:awardedOpportunities[1].Id].IsContractSent__c,'Contract for Swedish Account should not be upserted');
	}
}