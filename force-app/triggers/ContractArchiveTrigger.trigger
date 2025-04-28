/**
 * Created by kjachowicz on 12.12.2024.
 */

trigger ContractArchiveTrigger on Contract_Archive__c (after insert) {
   new ContractArchiveTriggerHandler().run();
}