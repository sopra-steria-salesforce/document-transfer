@isTest
public with sharing class FileUploadMultiControllerTest {

	@TestSetup
	static void set(){
		System.runAs(new User(Id=UserInfo.getUserId())) {
			TestingUtils.activateCustomPermission(UserInfo.getUserId(), 'ServiceNowContractUpsertTesting');
		}
		List<Opportunity> opportunity = TestDataFactory.createOpportunities(2, true, false);
		update new User(
				Id=UserInfo.getUserId(),
				Country='Norway'
		);

		Account parentAccount1 = new Account(Name = 'Test');
		insert parentAccount1;

		Account parentAccount2 = new Account(Name = 'Sopra Steria AS');
		insert parentAccount2;

		opportunity[0].AccountId = parentAccount1.Id;
		opportunity[0].OwnerId = UserInfo.getUserId();
		opportunity[0].StageName = Opportunities.AWARDED;

		opportunity[1].AccountId = parentAccount2.Id;
		opportunity[1].OwnerId = UserInfo.getUserId();
		opportunity[1].StageName = Opportunities.AWARDED;
		
		MetadataTriggerHandler.bypass('UpsertContractOnAwardedOpportunities');
		System.runAs(new User(Id=UserInfo.getUserId())){
			Assert.isTrue(FeatureManagement.checkPermission('ServiceNowContractUpsertTesting'),'ServiceNowContractUpsertTesting custom permission should be assigned');
			update opportunity;
		}
	}

	@isTest
	static void testOpportunityCountryMatchNavisionCountry() {
		List<Opportunity> opportunity = [SELECT Id, AccountId, OwnerId, StageName FROM Opportunity];
		MetadataTriggerHandler.bypass('UpsertContractOnNavisionChange');
		update new Account(
				Id = opportunity[0].AccountId,
				Navision_Customer_NO__c = true
		);
		
		Assert.isTrue(FileUploadMultiController.doesOpportunityCountryMatchNavisionCountry(opportunity[0].Id), 'Opportunity country should match Navision country.');
	}

	@IsTest
	static void testOpportunityCountryNotMatchNavisionCountry() {
		List<Opportunity> opportunity = [SELECT Id, AccountId, OwnerId, StageName, Owner_Country__c FROM Opportunity];
		MetadataTriggerHandler.bypass('UpsertContractOnNavisionChange');

		Assert.isFalse(FileUploadMultiController.doesOpportunityCountryMatchNavisionCountry(opportunity[0].Id), 'Opportunity country should not match Navision country.');
	}

	@IsTest
	static void testIgnoreNavisionCheckForSopraSteriaAS(){
		List<Opportunity> opportunity = [SELECT Id, AccountId, Name, OwnerId, StageName, Owner_Country__c FROM Opportunity];
		MetadataTriggerHandler.bypass('UpsertContractOnNavisionChange');
		
		Assert.isTrue(FileUploadMultiController.doesOpportunityCountryMatchNavisionCountry(opportunity[1].Id), 'Opportunity with account name "Sopra Steria AS" should not be checked for Navision country match.');
	}
}