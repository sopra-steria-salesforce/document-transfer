/**
 * Created by kjachowicz on 12.12.2024.*/
    @isTest
    public class ContractArchiveTriggerHandlerTest {
        @testSetup
        static void setup() {
            // Create test data
            List<Contract_Archive__c> contracts = new List<Contract_Archive__c>();
            for (Integer i = 0; i < 5; i++) {
                Contract_Archive__c contract = new Contract_Archive__c();
                contract.Sys_Id_External__c = 'SYS_ID_' + i;
                contracts.add(contract);
            }
            insert contracts;
        }

        @isTest
        static void testSendRequestToServiceNow() {
            // Get test data
            List<Contract_Archive__c> contracts = [SELECT Id FROM Contract_Archive__c];
            List<Id> contractIds = new List<Id>();
            for (Contract_Archive__c contract : contracts) {
                contractIds.add(contract.Id);
            }

            // Mock the HTTP response
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

            // Call the future method
            Test.startTest();
            ContractArchiveTriggerService.sendRequestToServiceNow(contractIds);
            Test.stopTest();

            // Verify the results
            // Add assertions as needed to verify the behavior
        }

        private class MockHttpResponseGenerator implements HttpCalloutMock {
            public HTTPResponse respond(HTTPRequest req) {
                // Create a fake response
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"status":"success"}');
                res.setStatusCode(200);
                return res;
            }
        }
    }