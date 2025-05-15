/**
 * Test class for ServiceNowUploadContractsController

 */
@isTest
private class ServiceNowUploadContractsControllerTest {
    
    /**
     * Setup test data
     */
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Create test opportunity with Contract Category
        Opportunity testOpportunity = new Opportunity(Type = 'Frame Agreement', Name = 'Test Opportunity With Category', StageName = '1 - Possibility', Status__c = '-', Business_Unit__c = 'APPS', CloseDate = Date.today(), Consultants__c = 1, Months__c = 1, AccountId = testAccount.Id, Proposal_Due_Date_Time__c = DateTime.now());

        insert testOpportunity;
        

    }
    
    /**
     * Test when a process is already running
     */
    @isTest
    static void testUploadWhenProcessAlreadyRunning() {
        // Get test opportunity
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity With Category' LIMIT 1];
        
        // Set the static flag to true to simulate a process already running
        Test.startTest();
        ServiceNowUploadContractsQueueable.isContractUploadProcessStarted = true;
        
        // Call the method
        ServiceNowUploadContractsController.ResponseWrapper response = 
            ServiceNowUploadContractsController.uploadContractToServiceNow(opp.Id);
        Test.stopTest();
        
        // Verify the response
        System.assertEquals(false, response.success, 'Success should be false when process is already running');
        System.assertEquals('A contract upload process is already in progress. Please wait for it to complete.', 
                           response.message, 'Error message should indicate process is already running');
    }
    
    /**
     * Test when opportunity is missing required fields
     */
   
    
    /**
     * Test successful upload initiation
     */
    @isTest
    static void testSuccessfulUploadInitiation() {
        // Get test opportunity with Contract Category
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity With Category' LIMIT 1];
        
        // Reset the static flag
        ServiceNowUploadContractsQueueable.isContractUploadProcessStarted = false;
        
        Test.startTest();
        // Call the method
        ServiceNowUploadContractsController.ResponseWrapper response = 
            ServiceNowUploadContractsController.uploadContractToServiceNow(opp.Id);
        Test.stopTest();

    }
    
    /**
     * Test exception handling
     */
    @isTest
    static void testExceptionHandling() {
        // Create a mock Id that doesn't exist to force an exception
        Id fakeId = '006000000000000AAA';
        
        // Reset the static flag
        ServiceNowUploadContractsQueueable.isContractUploadProcessStarted = false;
        
        Test.startTest();
        // Call the method with an invalid ID to force an exception
        ServiceNowUploadContractsController.ResponseWrapper response = 
            ServiceNowUploadContractsController.uploadContractToServiceNow(fakeId);
        Test.stopTest();
        
        // Verify the response
        System.assertEquals(false, response.success, 'Success should be false when an exception occurs');
        System.assert(String.isNotBlank(response.message), 'Error message should not be blank');
    }
    
    /**
     * Test ResponseWrapper constructor
     */
    @isTest
    static void testResponseWrapperConstructor() {
        // Create a new ResponseWrapper
        ServiceNowUploadContractsController.ResponseWrapper wrapper = 
            new ServiceNowUploadContractsController.ResponseWrapper();
        
        // Verify default values
        System.assertEquals(false, wrapper.success, 'Default success value should be false');
        System.assertEquals('', wrapper.message, 'Default message value should be empty string');
    }
}