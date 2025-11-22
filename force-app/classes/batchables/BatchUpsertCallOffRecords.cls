public with sharing class BatchUpsertCallOffRecords implements Database.Batchable<Call_Off_Contract__c>, Database.Stateful{
    private Map<String,Id> opportunityIdsByCallOffSysExternalIds;
    private List<Call_Off_Contract__c> callOffContracts;

	public BatchUpsertCallOffRecords(Map<String, Id> opportunityIdsByCallOffSysExternalIds, List<Call_Off_Contract__c> callOffContracts){
		this.opportunityIdsByCallOffSysExternalIds=opportunityIdsByCallOffSysExternalIds;
		this.callOffContracts=callOffContracts;
	}

    public Iterable<Call_Off_Contract__c> start(Database.BatchableContext info){
        return new CallOffContractIterable(callOffContracts); 
    }

    public void execute(Database.BatchableContext info, List<Call_Off_Contract__c> scope){
		try {
			upsert scope Sys_Id_External__c;
		}
		catch (DmlException dmlException){
			Logger.exception('Unexpected DML Exception when upserting call off contracts', scope,dmlException);
		}
		Map<Id, Id> callOffIdsByOpportunityIds = getCallOffIdsByOpportunityIds(scope);
		List<Opportunity> opportunities = [SELECT Id, Call_Off_Contract__c FROM Opportunity WHERE Id IN :callOffIdsByOpportunityIds.keySet()];
		for(Opportunity opportunity : opportunities) {
			opportunity.Call_Off_Contract__c = callOffIdsByOpportunityIds.get(opportunity.Id);
		}
		try {
			update opportunities;
		}
		catch (DmlException dmlException){
			Logger.exception('Unexpected DML Exception when updating Opportunities with call off contract reference', scope,dmlException);
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
		AsyncApexJob job = [
				SELECT NumberOfErrors
				FROM AsyncApexJob
				WHERE Id = :info.getJobId()
		];
		if (job.NumberOfErrors==0) {
			ServiceNow_Settings__c settings = [SELECT Id, LastCallOffSynchronizationTime__c FROM ServiceNow_Settings__c LIMIT 1];
			settings.LastCallOffSynchronizationTime__c = Datetime.now().addHours(-2);
			update settings;
		}
    }
}