public with sharing class BatchUpsertCallOffRecords implements Database.Batchable<Call_Off_Contract__c>, Database.Stateful{
    public static Map<String,String> opportunityId2CalloffSysExternalId;
    public static List<Call_Off_Contract__c> callOffContracts;
    private static ServiceNow_Settings__c settings = [SELECT Id, LastCallOffSynchronizationTime__c FROM ServiceNow_Settings__c LIMIT 1];
    
    public Iterable<Call_Off_Contract__c> start(Database.BatchableContext info){ 
        Logger.info('start BatchUpsertCallOffRecords');
        return new CallOffContractIterable(callOffContracts); 
    }

    public void execute(Database.BatchableContext info, List<Call_Off_Contract__c> callOffContracts){
      Boolean foundError = false;
        Database.UpsertResult[] upsertResults = Database.upsert(callOffContracts, Call_Off_Contract__c.fields.Sys_Id_External__c, false);
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
            List<Call_Off_Contract__c> callOffContractsList = [SELECT Id, Sys_Id_External__c FROM Call_Off_Contract__c WHERE Sys_Id_External__c IN :opportunityId2CalloffSysExternalId.values()];
            Map<String,String> externalId2contractId = new Map<String,String>();
            for(Call_Off_Contract__c callOff : callOffContractsList){
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