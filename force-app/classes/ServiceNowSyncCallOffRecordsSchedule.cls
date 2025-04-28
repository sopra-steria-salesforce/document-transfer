/**
 * Created by kjachowicz on 20.11.2024.
 */

global with sharing class ServiceNowSyncCallOffRecordsSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        ServiceNowSyncCallOffRecords.syncCallOffRecords();
    }
}