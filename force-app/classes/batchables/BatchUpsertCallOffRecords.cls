public with sharing class BatchUpsertCallOffRecords implements Database.Batchable<sObject>, Database.Stateful{
    static Map<String,String> opportunityId2CalloffSysExternalId = new Map<String, String>();
    private List<Call_Off_Contract__c> callOffContracts = new List<Call_Off_Contract__c>();
    
    public BatchUpsertCallOffRecords(Map<String,String> opportunityId2CalloffSysExternalId, List<Call_Off_Contract__c> callOffContracts) {
        this.opportunityId2CalloffSysExternalId = opportunityId2CalloffSysExternalId;
        this.callOffContracts = callOffContracts;
    }
    
    public Iterable start(Database.BatchableContext info){ 
        return new CallOffContractIterable(callOffContracts); 
    }

    public void execute(Database.BatchableContext info, List<Call_Off_Contract__c> callOffContracts){
      Boolean foundError = false;
        Database.UpsertResult[] upsertResults = Database.upsert(callOffRecords, Call_Off_Contract__c.Fields.Sys_Id_External__c, false);
        Logger.info('upsertResults: ', upsertResults).addTag('Sync call off records');
        for (Database.UpsertResult upsertResult : upsertResults) {
             Logger.info('upsertResult', upsertResult).addTag('Sync call off records');
            if (!upsertResult.isSuccess()) {
                for (Database.Error error : upsertResult.getErrors()) {
                    Logger.error('Error: ' + error.getStatusCode() + error.getMessage()).addTag('Sync call off records');
                    foundError = true;
                }
            }
        }
        Logger.saveLog();

        if(!foundError) {
            List<Call_Off_Contract__c> callOffContracts = [SELECT Id, Sys_Id_External__c FROM Call_Off_Contract__c WHERE Sys_Id_External__c IN :opportunityId2CalloffSysExternalId.values()];
            Map<String,String> externalId2contractId = new Map<String,String>();
            for(Call_Off_Contract__c callOff : callOffContracts){
                externalId2contractId.put(callOff.Sys_Id_External__c, callOff.Id);
            }
            List<Opportunity> opportunities = [SELECT Id, Call_Off_Contract__c FROM Opportunity WHERE Id IN :opportunityId2CalloffSysExternalId.keySet()];
            for(Opportunity opp : opportunities) {
                opp.Call_Off_Contract__c = externalId2contractId.get(opportunityId2CalloffSysExternalId.get(opp.Id));
            }
            Database.update(opportunities,true);
            settings.LastCallOffSynchronizationTime__c = Datetime.now().addHours(-2);
            update settings;
        }
    }     

    public void finish(Database.BatchableContext info){     
    }
}