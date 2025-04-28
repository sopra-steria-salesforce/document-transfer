/**
 * Created by kjachowicz on 12.12.2024.
 */

public class ContractArchiveTriggerHandler extends TriggerHandler {
    private List<Contract_Archive__c> newList;
    private Map<Id,Contract_Archive__c> newMap;
    private Map<Id,Contract_Archive__c> oldMap;

    public ContractArchiveTriggerHandler() {
        this.newList = (List<Contract_Archive__c>) Trigger.new;
        this.oldMap = (Map<Id,Contract_Archive__c>) Trigger.oldMap;
        this.newMap = (Map<Id,Contract_Archive__c>) Trigger.newMap;
    }
    public override void afterInsert() {
        List<Id> contractIds = new List<Id>();
        for(Contract_Archive__c contractArchive : newList) {
            contractIds.add(contractArchive.Id);
        }
        if(!System.isFuture()){
            ContractArchiveTriggerService.sendRequestToServiceNow(contractIds);
        }
    }

}