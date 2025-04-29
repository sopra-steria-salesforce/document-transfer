public with sharing class Utils {
    // REQUEST
    public static final String CONTENT_TYPE = 'Content-Type';
    public static final String METHOD_GET = 'GET';
    public static final String METHOD_POST = 'POST';
    public static final String METHOD_PATCH = 'PATCH';
    public static final String APPLICATION_JSON = 'application/json;charset=UTF-8';
    public static final String APPLICATION_PDF = 'application/pdf';

    //ACCOUNT
    // STATUS
    public static final String ACTIVE = 'Active';
    public static final String NOT_IN_BRREG = 'Not in Brreg';
    public static final String CHECKING_IN_BRREG = 'Checking in Brreg';

    //OPPORTUNITY
    public static final String YES = 'Yes';
    public static final String NO = 'No';
    //STAGENAME
    public static final String PLANNING_0 = '0 - Planning';
    public static final String OFFER_4 = '4 - Offer';
    public static final String CLOSED_WON = 'Closed Won';
    //BUSINESS UNIT
    public static final String BC = 'BC';
    public static final String APPS = 'APPS';
    public static final String ADVISORY = 'Advisory';
    public static final String DPS = 'dps';
    public static final String dps_owner = 'DPS_Owner__c';
    public static final String advisory_owner = 'BC_owner__c';
    public static final String apps_Owner = 'Apps_Owner__c';

    //SERVICE NOW
    public static final String NAMED_CREDENTIAL_SERVICE_NOW = 'callout:ServiceNowContracts';
    public static final String API_GET_ALL_CONTRACTS = '/getAllContractsWithCustomers?start_date=2021-01-01&end_date=2021-12-31';
    public static final String API_GET_ALL_ARCHIVES = '/getAllArchives2SF';
    public static final String API_CREATE_NEW_CONTRACTS = '/createNewContract';
    public static final String API_GET_ALL_CUSTOMERS_WITH_CONTRACTS = '/getAllCustomersWithContracts';
    public static final String API_GET_ALL_CONTRACTS_AND_CUSTOMERS_M2M = '/getAllContractsM2MCompaniesRel';
    public static final String API_UPDATE_EXISTING_CONTRACTS = '/updateExistingContract';
    public static final String API_ADD_ATTACHMENT_NEW_CONTRACTS = '/addAttachmentsNewContract';
    public static final String API_ADD_ATTACHMENT_EXISTING_CONTRACTS = '/addAttachmentsExistingContract';
    public static final String API_ADD_ID_TO_CONTRACT = '/addID2Contract';
    public static final String API_GET_ALL_AGREEMENTS = '/getAllAgreements';

    public static String isNull(String input){
        return input == null ? null : input;
    }

    public static HttpResponse doRequest(String namedCredentials,String apiMethodName,String httpMethod,String body){
        Logger.debug('body:', body);
        Logger.debug('nameCredentials', namedCredentials);
        Logger.debug('apiMethodName', apiMethodName);
        HttpRequest httpRequestServiceNowContracts = new HttpRequest();
        httpRequestServiceNowContracts.setEndpoint(namedCredentials+apiMethodName);
        httpRequestServiceNowContracts.setMethod(httpMethod);
        httpRequestServiceNowContracts.setHeader(CONTENT_TYPE,APPLICATION_JSON);
        if(httpMethod == METHOD_PATCH || httpMethod == METHOD_POST){
            httpRequestServiceNowContracts.setBody(body);
        }
        Http httpServiceNowContracts = new Http();
        httpRequestServiceNowContracts.setTimeout(20000);
        HttpResponse response = new HttpResponse();
        try{
            response = httpServiceNowContracts.send(httpRequestServiceNowContracts);
            Logger.debug('response' + response, response.getBody());
        }catch(Exception e){
            Logger.error('Callout errror', e);
        }
        Logger.saveLog();
        return response;
    }
    @AuraEnabled
    public static void logFailure(String className, String methodName, String errorMessage, String status, String userInfo, String additionalContext) {
        Application_Log__c log = new Application_Log__c();
        log.Class_Name__c = className;
        log.Method_Name__c = methodName;
        log.Error_Message__c = errorMessage;
        log.Status__c = status;
        log.Timestamp__c = Datetime.now();
        log.User_Info__c = userInfo;
        log.Additional_Context__c = additionalContext;
        insert log;
    }
        @AuraEnabled
        public static void logFailureFromUpload(String className, String methodName, String errorMessage, String status, String userInfo, String additionalContext, List<Object> files) {

            Application_Log__c log = new Application_Log__c();
            log.Class_Name__c = className;
            log.Method_Name__c = methodName;
            log.Error_Message__c = errorMessage;
            log.Status__c = status;
            log.Timestamp__c = Datetime.now();
            log.User_Info__c = userInfo;
            log.Additional_Context__c = additionalContext;
            insert log;

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'ExampleFile.pdf';
        contentVersion.PathOnClient = 'ExampleFile.pdf';
      //  contentVersion.VersionData = EncodingUtil.base64Decode(base64Content);
        insert contentVersion;

        ContentVersion insertedContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = insertedContentVersion.ContentDocumentId;
        contentDocumentLink.LinkedEntityId = log.Id; // Replace with the ID of the record you want to link to
        contentDocumentLink.ShareType = 'V';
        contentDocumentLink.Visibility = 'AllUsers';
        insert contentDocumentLink;
    }
            }