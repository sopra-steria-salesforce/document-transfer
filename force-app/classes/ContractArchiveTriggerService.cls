/**
 * Created by kjachowicz on 12.12.2024.
 */

public with sharing class ContractArchiveTriggerService {
    @future(callout=true)
    public static void sendRequestToServiceNow(List<Id> contractIds) {
        Map<Id,Contract_Archive__c> contracts = new Map<Id,Contract_Archive__c>([SELECT Id, Sys_Id_External__c FROM Contract_Archive__c WHERE Id IN :contractIds]);
        List<RequestWrapper> requests = new List<RequestWrapper>();
        for(Id contractId : contractIds) {
           RequestWrapper request = new RequestWrapper(contracts.get(contractId).Sys_Id_External__c, contractId);
           requests.add(request);
        }
        HttpResponse response = Utils.doRequest(
                Utils.NAMED_CREDENTIAL_SERVICE_NOW,
                Utils.API_ADD_ID_TO_CONTRACT,
                Utils.METHOD_PATCH,
                JSON.serialize(requests)
        );
        if (response.getStatusCode() == 200) {
            Logger.info('Request sent successfully.');
        } else {
            Logger.error('Failed to send request: ' + response.getStatusCode() + ' ' + response.getStatus());
            Logger.saveLog();
        }
    }

    public class RequestWrapper {
        String contract_sys_id;
        String contract_salesforce_id;

        public RequestWrapper(String contract_sys_id, String contract_salesforce_id) {
            this.contract_sys_id = contract_sys_id;
            this.contract_salesforce_id = contract_salesforce_id;
        }
    }
}