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
    static void testOpportunityOwnerCountryMatchesNavisionCustomerCountry(){
        List<Opportunity> opportunities = TestDataFactory.createOpportunities(2,false,true);
        UpsertContractOnAwardedOpportunities.parentAccountsByIds=new Map<Id, Account>{
                opportunities[0].AccountId => new Account(Navision_Customer_NO__c=true),
                opportunities[1].AccountId => new Account(Navision_Customer_SE__c=true)
        };
        UpsertContractOnAwardedOpportunities.opportunityOwnersByIds=new Map<Id, User>{UserInfo.getUserId()=>new User(Country='Sweden')};
        opportunities[0].OwnerId = UserInfo.getUserId();
        opportunities[1].OwnerId = UserInfo.getUserId();

        Assert.isFalse(UpsertContractOnAwardedOpportunities.doesOpportunityOwnerCountryMatchNavisionCustomerCountry(opportunities[0]),'Norwegian Opportunity should not match Swedish Account');
        Assert.isTrue(UpsertContractOnAwardedOpportunities.doesOpportunityOwnerCountryMatchNavisionCustomerCountry(opportunities[1]),'Swedish Opportunity should match Swedish Account');
    }

    @IsTest
    static void shouldEnqueueServiceNowUploadContractsQueueable() {
        DML.isMockDML = true;
        List<Account> accounts = TestDataFactory.createAccounts(2, false,false);
        accounts[0].Navision_Customer_NO__c=true;
        accounts[1].Navision_Customer_SE__c=true;
        insert accounts;
        List<Opportunity> oldOpportunities = TestDataFactory.createOpportunities(2, false, true);
        oldOpportunities[0].AccountId = accounts[0].Id;
        oldOpportunities[1].AccountId = accounts[1].Id;
        User u = new User(Id = UserInfo.getUserId(), Country = 'Sweden');
        update u;

        oldOpportunities[0].OwnerId = u.Id;
        oldOpportunities[1].OwnerId = u.Id;
        oldOpportunities[0].New_or_Renewal__c = 'New';
        oldOpportunities[1].New_or_Renewal__c = 'New';

        List<Opportunity> newOpportunities = oldOpportunities.deepClone(true);
        newOpportunities[0].StageName = Utils.AWARDED;
        newOpportunities[1].StageName = Utils.AWARDED;
        UpsertContractOnAwardedOpportunities testUpsertContractOnAwardedOpportunities = new UpsertContractOnAwardedOpportunities();

        testUpsertContractOnAwardedOpportunities.beforeUpdate(newOpportunities, oldOpportunities);

        Assert.areEqual(1,DML.enqueuedJobs.size(), '1 Queueable job should be queued');
        Assert.isInstanceOfType(DML.enqueuedJobs[0], ServiceNowUploadContractsQueueable.class, 'ServiceNowUploadContractsQueueable should be queued');
    }
}