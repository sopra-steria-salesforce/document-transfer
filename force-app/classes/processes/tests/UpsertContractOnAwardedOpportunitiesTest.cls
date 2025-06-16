@IsTest
public with sharing class UpsertContractOnAwardedOpportunitiesTest {
    @IsTest
    static void testOpportunityStageHasNotChangedToAwarded() {
        Opportunity oldOpportunity = TestDataFactory.createOpportunities(1, false, true)[0];
        oldOpportunity.StageName = Utils.PLANNING_0;
        Opportunity newOpportunity = oldOpportunity.clone(true);
        Assert.isFalse(UpsertContractOnAwardedOpportunities.hasOpportunityStageChangedToAwarded(oldOpportunity, newOpportunity));
    }

    @IsTest
    static void testOpportunityStageHasChangedToAwarded() {
        Opportunity oldOpportunity = TestDataFactory.createOpportunities(1, false, true)[0];
        oldOpportunity.StageName = Utils.PLANNING_0;
        Opportunity newOpportunity = oldOpportunity.clone(true);
        newOpportunity.StageName = Utils.AWARDED;
        Assert.isTrue(UpsertContractOnAwardedOpportunities.hasOpportunityStageChangedToAwarded(oldOpportunity, newOpportunity));
    }

    @IsTest
    static void shouldEnqueueServiceNowUploadContractsQueueable() {
        DML.isMockDML = true;
        List<Opportunity> oldOpportunities = TestDataFactory.createOpportunities(2, false, true);
        oldOpportunities[0].Account.Navision_Customer_NO__c = true;
        oldOpportunities[1].Account.Navision_Customer_SE__c = true;
        User u = new User(Id = UserInfo.getUserId(), Country = 'Sweden');
        oldOpportunities[0].Owner = u;
        oldOpportunities[1].Owner = u;
        oldOpportunities[0].New_or_Renewal__c = 'New';
        oldOpportunities[1].New_or_Renewal__c = 'New';
        List<Opportunity> newOpportunities = oldOpportunities.deepClone(true);
        newOpportunities[0].StageName = Utils.AWARDED;
        newOpportunities[1].StageName = Utils.AWARDED;
        UpsertContractOnAwardedOpportunities testUpsertContractOnAwardedOpportunities = new UpsertContractOnAwardedOpportunities();

        Test.startTest();
        testUpsertContractOnAwardedOpportunities.beforeUpdate(newOpportunities, oldOpportunities);
        Test.stopTest();

        Assert.isFalse(DML.enqueuedJobs.isEmpty(), '1 Queueable job should be queued');
        Assert.isInstanceOfType(DML.enqueuedJobs[0], ServiceNowUploadContractsQueueable.class, 'ServiceNowUploadContractsQueueable should be queued');
    }
}
