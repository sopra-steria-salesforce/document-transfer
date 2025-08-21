@isTest
public with sharing class FileUploadMultiControllerTest {

	@TestSetup
	static void set(){
		System.runAs(new User(Id=UserInfo.getUserId())) {
			TestingUtils.activateCustomPermission(UserInfo.getUserId(), 'ServiceNowContractUpsertTesting');
		}
		List<Opportunity> opportunity = TestDataFactory.createOpportunities(1, true, false);
		update new User(
				Id=UserInfo.getUserId(),
				Country='Norway'
		);

		Account parentAccount = new Account(Name = 'Test');
		insert parentAccount;

		opportunity[0].AccountId = parentAccount.Id;
		opportunity[0].OwnerId = UserInfo.getUserId();
		opportunity[0].StageName = Opportunities.AWARDED;
		
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
}