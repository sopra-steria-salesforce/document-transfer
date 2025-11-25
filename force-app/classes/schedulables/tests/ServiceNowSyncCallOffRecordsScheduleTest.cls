/**
 * Created by kjachowicz on 04.12.2024.
 */
@IsTest
public with sharing class ServiceNowSyncCallOffRecordsScheduleTest {

        public static String CRON_EXP = '0 0 0 15 3 ? 2050';

    static testmethod void testSchedule() {
        ServiceNow_Settings__c settings = new ServiceNow_Settings__c(Name = 'Test',LastCallOffSynchronizationTime__c = DateTime.now().addDays(-1),LastContractsSynchronization__c = DateTime.now().addDays(-1));
        insert settings;
        Test.startTest();
            String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, new ServiceNowSyncCallOffRecordsSchedule());
            CronTrigger ct = [
                    SELECT Id, CronExpression, TimesTriggered, NextFireTime
                    FROM CronTrigger
                    WHERE id = :jobId
            ];
            System.assertEquals(CRON_EXP, ct.CronExpression);
            Test.stopTest();
        }
    }