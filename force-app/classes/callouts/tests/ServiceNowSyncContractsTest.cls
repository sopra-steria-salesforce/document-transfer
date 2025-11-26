/**
 * Created by kjachowicz on 16.10.2024.
 */
@IsTest
public with sharing class ServiceNowSyncContractsTest {

    @IsTest
    public static void serviceNowSyncTest(){

        ServiceNow_Settings__c settings = new ServiceNow_Settings__c();
        settings.Name ='ServiceNow Settings';
        settings.LastContractsSynchronization__c = Datetime.now();
        insert settings;

        Contract_Archive__c contractArchive = new Contract_Archive__c();
        contractArchive.Name = 'Contract Archive';
        contractArchive.Sys_Id_External__c = 'test';
        insert contractArchive;

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setHeader('Content-Type', 'application/json');
        mock.setStatusCode(200);
        mock.setStaticResource('syncContractsResponse');
		Test.setMock(HttpCalloutMock.class, mock);
		
        Test.startTest();
        ServiceNowSyncContractArchiveRecords.syncContractArchiveRecords();
        Test.stopTest();
    }
}