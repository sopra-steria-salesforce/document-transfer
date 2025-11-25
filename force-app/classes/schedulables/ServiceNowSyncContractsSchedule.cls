/**
 * Created by kjachowicz on 09.10.2024.
 */
global class ServiceNowSyncContractsSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        ServiceNowSyncContractArchiveRecords.syncContractArchiveRecords();
    }
}