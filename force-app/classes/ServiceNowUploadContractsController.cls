/**
 * Controller for the ServiceNowUploadContracts Lightning component
 * Handles the button click to upload contracts to ServiceNow
 */
public with sharing class ServiceNowUploadContractsController {
    
    /**
     * Initiates the contract upload process for the specified opportunity
     * @param opportunityId The ID of the opportunity to process
     * @return A wrapper containing success/error information
     */
    @AuraEnabled
    public static ResponseWrapper uploadContractToServiceNow(Id opportunityId) {
        ResponseWrapper response = new ResponseWrapper();
        Logger.debug('OpportunityId', opportunityId);
        
        try {
            // Check if a process is already running
            if (ServiceNowUploadContractsQueueable.isContractUploadProcessStarted) {
                response.success = false;
                response.message = 'A contract upload process is already in progress. Please wait for it to complete.';
                return response;
            }
            
            // Get the opportunity record
            Opportunity opp = [
                SELECT Id, Name, Contract_Category__c, AccountId, Sub_Area__c, Contract_Lookup__c
                FROM Opportunity 
                WHERE Id = :opportunityId
                LIMIT 1
            ];
            
            // Validate opportunity has required fields
            if (String.isBlank(opp.Contract_Category__c)) {
                response.success = false;
                response.message = 'Contract Category is required to upload contracts to ServiceNow.';
                return response;
            }
            
            // Enqueue the job
            System.enqueueJob(new ServiceNowUploadContractsQueueable(opp));
            
            response.success = true;
            response.message = 'Contract upload process has been initiated. You will be notified when complete.';
        } catch (Exception ex) {
            response.success = false;
            Logger.error('Exception occurred during button click', ex);
            
        }
        Logger.debug('Response from uploadContractToServiceNow' + response);
        Logger.saveLog();
        return response;
    }
    
    /**
     * Wrapper class for the response
     */
    public class ResponseWrapper {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        
        public ResponseWrapper() {
            this.success = false;
            this.message = '';
        }
    }
}