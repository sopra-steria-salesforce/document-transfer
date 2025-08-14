/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
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
		
		Assert.isTrue(FileUploadMultiController.doesOpportunityCountryMatchNavisionCountry(opportunity[0]), 'Opportunity country should match Navision country.');
	}

	@IsTest
	static void testOpportunityCountryNotMatchNavisionCountry() {
		List<Opportunity> opportunity = [SELECT Id, AccountId, OwnerId, StageName, Owner_Country__c FROM Opportunity];
		MetadataTriggerHandler.bypass('UpsertContractOnNavisionChange');

		update new Account(
			Id = opportunity[0].AccountId,
			Navision_Customer_NO__c = false
		);

		Assert.isFalse(FileUploadMultiController.doesOpportunityCountryMatchNavisionCountry(opportunity[0]), 'Opportunity country should not match Navision country.');
	}
}