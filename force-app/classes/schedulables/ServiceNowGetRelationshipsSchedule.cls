/**
 * Created by kjachowicz on 20.11.2024.
 */

public with sharing class ServiceNowGetRelationshipsSchedule implements Schedulable {

    public void execute(SchedulableContext param1) {
        ServiceNowGetRelationships.assignContractsWithAccounts();
        
    }
}