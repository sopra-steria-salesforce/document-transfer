@isTest private class ServiceNowGetRelationshipsScheduleTest {

    public static String CRON_EXP = '0 0 0 15 3 ? 2050';

    static testmethod void testSchedule() {
        Test.startTest();
        String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, new ServiceNowGetRelationshipsSchedule());
        CronTrigger ct = [
                SELECT Id, CronExpression, TimesTriggered, NextFireTime
                FROM CronTrigger
                WHERE id = :jobId
        ];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        Test.stopTest();
    }
}