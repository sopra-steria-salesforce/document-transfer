public with sharing class BatchUpsertCallOffRecords implements Database.Batchable<Call_Off_Contract__c>, Database.Stateful{
    private Map<String,Id> opportunityIdsByCallOffSysExternalIds;
    private List<Call_Off_Contract__c> callOffContracts;
    private static ServiceNow_Settings__c settings = [SELECT Id, LastCallOffSynchronizationTime__c FROM ServiceNow_Settings__c LIMIT 1];

	public BatchUpsertCallOffRecords(Map<String, Id> opportunityIdsByCallOffSysExternalIds, List<Call_Off_Contract__c> callOffContracts){
		this.opportunityIdsByCallOffSysExternalIds=opportunityIdsByCallOffSysExternalIds;
		this.callOffContracts=callOffContracts;
	}

    public Iterable<Call_Off_Contract__c> start(Database.BatchableContext info){
        return new CallOffContractIterable(callOffContracts); 
    }

    public void execute(Database.BatchableContext info, List<Call_Off_Contract__c> scope){
		Boolean foundError = false;
        Database.UpsertResult[] upsertResults = Database.upsert(scope, Call_Off_Contract__c.fields.Sys_Id_External__c, false);
        for (Database.UpsertResult upsertResult : upsertResults) {
             Logger.info('upsertResult', upsertResult).addTag('Sync call off records');
            if (!upsertResult.isSuccess()) {
                for (Database.Error error : upsertResult.getErrors()) {
                    Logger.error('Error: ' + error.getStatusCode() + error.getMessage()).addTag('Sync call off records');
                    foundError = true;
                }
            }
        }
        if(!foundError) {
			Map<Id, Id> callOffIdsByOpportunityIds = getCallOffIdsByOpportunityIds(scope);
            List<Opportunity> opportunities = [SELECT Id, Call_Off_Contract__c FROM Opportunity WHERE Id IN :callOffIdsByOpportunityIds.keySet()];
            for(Opportunity opportunity : opportunities) {
                opportunity.Call_Off_Contract__c = callOffIdsByOpportunityIds.get(opportunity.Id);
            }
            update opportunities;
        } else{
			Logger.saveLog();
		}
    }
	/**
	 * @description: Get subset of Opportunities related to this batch of Call Off Contracts
	 */
	private Map<Id, Id> getCallOffIdsByOpportunityIds(List<Call_Off_Contract__c> callOffContracts){
		Map<Id, Id> callOffIdsByOpportunityIds = new Map<Id, Id>();
		for (Call_Off_Contract__c callOffContract:callOffContracts){
			callOffIdsByOpportunityIds.put(this.opportunityIdsByCallOffSysExternalIds.get(callOffContract.Sys_Id_External__c), callOffContract.Id);
		}
		return callOffIdsByOpportunityIds;
	}

    public void finish(Database.BatchableContext info){
		settings.LastCallOffSynchronizationTime__c = Datetime.now().addHours(-2);
		update settings;
    }
}