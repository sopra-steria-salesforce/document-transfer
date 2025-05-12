/**
 * Created by kjachowicz on 28.09.2023.
 */

public with sharing class ServiceNowUploadContracts {
    static String contract_sys_id;
    static String internal_contract_number;
    static String relationship_sys_id;
    static Opportunity opportunity;
    static String truncatedUsername ;
    static Map<String,String> country2LegalOwner = new Map<String,String>{
            'Norway' => 'Sopra Steria Norway',
            'Sweden' => 'Sopra Steria Sweden',
            'Denmark' => 'Sopra Steria Denmark'
    };

    @AuraEnabled
    public static ResponseWrapper uploadContracts(String recordId,String filedata, Boolean contractLookup, String opportunityContractSysId, String customerName, String contractNumber) {
        Logger.info('filedata' + filedata).addTag('Upload contracts');
        opportunity = ServiceNowIntegrationSelector.retrieveOpportunity(recordId);
        truncatedUsername = opportunity.Owner.Username.replace('.uat','');
        try {
            if (String.isNotBlank(filedata)) {
                List<Attachment> files = (List<Attachment>) JSON.deserialize(filedata, List<Attachment>.class);
                if (!contractLookup && opportunityContractSysId == null) {
                    return uploadNewContract(files,customerName,contractNumber);
                } else {
                    return uploadExistingContract(files,customerName,contractNumber);
                }
            }
        }catch (Exception ex){
            Logger.error('Exception occurred during API call. ', ex).addTag('Upload contracts');
            Logger.saveLog();
            throw new AuraHandledException(ex.getMessage());
        }
        return null;
    }

    private static ResponseWrapper uploadNewContract(List<Attachment> files, String customerName, String customerNumber) {
        createNewContracts(customerNumber,customerName);
        OuterWrapper outerWrapper = addAttachmentToNewContracts(files,customerName,customerNumber);
        if(outerWrapper == null){
            Logger.error('Failed to upload attachments. ' + outerWrapper.result.message).addTag('Upload contracts');
            Logger.saveLog();
            return null;
        }
        Contract_Archive__c archive = createNewContractArchive(customerName);
        Account_Contract_Archive_Junction__c junction = createJunction(archive.Id, internal_contract_number);
        updateOpportunity(archive.Id, junction.Id,null);
        return outerWrapper.result;
    }

    private static ResponseWrapper uploadExistingContract(List<Attachment> attachments,String customerName, String contractNumber){

        createExistingContracts(customerName,contractNumber);
        OuterWrapper outerWrapper =  addAttachmentToExistingContracts(attachments,customerName,contractNumber);
        Call_Off_Contract__c callOff = createCallOff(outerWrapper,customerName,contractNumber);
        updateOpportunity(null,null,calloff != null ? callOff.Id : null);
        return outerWrapper.result;
    }

    private static AttachmentNewContractBody prepareBodyForNewContractAttachment(List<Attachment> files,String customerName, String contractNumber) {
        AttachmentNewContractBody requestBody = new AttachmentNewContractBody(
                contract_sys_id,
                files,
                truncatedUsername,
                opportunity.Comments__c == null ? ' ' : opportunity.Comments__c,
                opportunity.Contract_Category__c,
                customerName != null ? customerName : opportunity.Name,
                contractNumber != null ? contractNumber : ' '
        );
        return requestBody;
    }

    private static AttachmentExistingContractBody prepareBodyForExistingContractAttachment(List<Attachment> files,String customerName, String contractNumber){
        String contractId = opportunity.ContractSysId__c != null ? opportunity.ContractSysId__c : opportunity.Contract_Lookup__r.Sys_Id_External__c;
        AttachmentExistingContractBody requestBody = new AttachmentExistingContractBody(
                opportunity.Id,
                contractId,
                files,
                opportunity.Call_Off_Contract__r.Sys_Id_External__c != null ? opportunity.Call_Off_Contract__r.Sys_Id_External__c : '',
                truncatedUsername,
                opportunity.Comments__c == null ? ' ' : opportunity.Comments__c,
                opportunity.Sub_Area__c,
                opportunity.Contract_Category__c,
                customerName != null ? customerName : opportunity.Name,
                contractNumber
        );
        return requestBody;
    }

    private static NewContractBody prepareBodyForCreateNewContracts(String customerNumber,String customerName){
        Logger.info('customerName' + customerName).addTag('Upload contracts');

        NewContractBody requestBody = new NewContractBody(
                opportunity.Id,
                String.isNotBlank(customerNumber) ? customerName : opportunity.Name,
                truncatedUsername,
                customerNumber != null ? customerNumber : ' '
        );
        return requestBody;
    }

    private static UpdateExistingContractBody prepareBodyForCreateExistingContracts(String customerName,String customerNumber){
        UpdateExistingContractBody requestBody = new UpdateExistingContractBody(
                opportunity.Contract_Lookup__r.Sys_Id_External__c,
                opportunity.Id,
                '',
                '',
                opportunity.Sub_Area__c,
                customerName != null ? customerName : opportunity.Name,
                customerNumber
        );
        return requestBody;
    }

    private static void createExistingContracts(String customerName, String customerNumber) {
        try {
            HttpResponse response = Utils.doRequest(
                    Utils.NAMED_CREDENTIAL_SERVICE_NOW,
                    Utils.API_UPDATE_EXISTING_CONTRACTS,
                    Utils.METHOD_PATCH,
                    JSON.serialize(prepareBodyForCreateExistingContracts(customerName, customerNumber))
            );
            if (response.getStatusCode() != 200){
                Logger.error('API call failed' + response.getStatusCode()).addTag('Upload contracts');
                Logger.error('Response body'+ response.getBody()).addTag('Upload contracts');
            }
        } catch (Exception e) {
            Logger.error('Exception occurred during API call', e).addTag('Upload contracts');
            Logger.saveLog();
        }
    }

    private static void createNewContracts(String customerNumber, String customerName) {
        try {
            HttpResponse response = Utils.doRequest(
                    Utils.NAMED_CREDENTIAL_SERVICE_NOW,
                    Utils.API_CREATE_NEW_CONTRACTS,
                    Utils.METHOD_POST,
                    JSON.serialize(prepareBodyForCreateNewContracts(customerNumber, customerName))
            );
            if (response.getStatusCode() == 200) {
                OuterWrapper outerWrapper = deserializeResponse(response);
                assignContractSysId(outerWrapper);
            }
        } catch (Exception e) {
            Logger.error('Exception occurred during API call', e).addTag('Upload contracts');
            Logger.saveLog();
        }
    }

    private static OuterWrapper addAttachmentToNewContracts(List<Attachment> files, String customerName, String contractNumber) {
        try {
            HttpResponse response = Utils.doRequest(
                    Utils.NAMED_CREDENTIAL_SERVICE_NOW,
                    Utils.API_ADD_ATTACHMENT_NEW_CONTRACTS,
                    Utils.METHOD_PATCH,
                    JSON.serialize(prepareBodyForNewContractAttachment(files, customerName, contractNumber))
            );
            if (response.getStatusCode() == 200) {
                return deserializeResponse(response);
            } else {
                Logger.error('API call failed' + response.getStatusCode()).addTag('Upload contracts');
                Logger.error('Response body' + response.getBody()).addTag('Upload contracts');
                return null;
            }
        } catch (Exception e) {
            Logger.error('Exception occurred during API call', e).addTag('Upload contracts');
            Logger.saveLog();
            return null;
        }
    }

    private static Call_Off_Contract__c createCallOff(OuterWrapper outerWrapper, String customerName, String contractNumber){
        if(opportunity.Contract_Category__c == 'New call off (Agreement on existing contract)') {
            Call_Off_Contract__c callOff = new Call_Off_Contract__c();
            callOff.Sys_Id_External__c = outerWrapper.result.task_sys_id;
            callOff.Name = customerName;
            callOff.Contract_Number__c = contractNumber;
            callOff.Parent_Contract__c = opportunity.Contract_Lookup__c;
            callOff.Number__c = outerWrapper.result.task_number;
            callOff.Account__c = opportunity.AccountId;
            insert callOff;
            return callOff;
        }else{
            return null;
        }
    }

    private static OuterWrapper addAttachmentToExistingContracts(List<Attachment> files, String customerName, String contractNumber) {
        try {
            HttpResponse response = Utils.doRequest(
                    Utils.NAMED_CREDENTIAL_SERVICE_NOW,
                    Utils.API_ADD_ATTACHMENT_EXISTING_CONTRACTS,
                    Utils.METHOD_PATCH,
                    JSON.serialize(prepareBodyForExistingContractAttachment(files, customerName, contractNumber))
            );
            if (response.getStatusCode() == 200){
                return deserializeResponse(response);
            } else {
                Logger.error('API call failed, response' + response.getBody()).addTag('Upload contracts');
                Logger.error('Status code' + response.getStatusCode()).addTag('Upload contracts');
                return null;
            }
        } catch (Exception e) {
            Logger.error('Exception occurred during API call', e).addTag('Upload contracts');
            Logger.saveLog();
            return null;
        }
    }

    private static Contract_Archive__c createNewContractArchive(String customerName){
        Contract_Archive__c archive = new Contract_Archive__c();
        User currentUser = [SELECT Id,Country FROM User WHERE Id =:UserInfo.getUserId()];
        archive.LegalOwner__c = country2LegalOwner.get(currentUser.Country);
        archive.Name = customerName;
        archive.Sys_Id_External__c = contract_sys_id;
        archive.Internal_Contract_Number__c = internal_contract_number;
        archive.Primary_Customer__c = opportunity.AccountId;
        insert archive;
        return archive;
    }

    private static Account_Contract_Archive_Junction__c createJunction (Id archiveId, String internalContractNumber){
        Account_Contract_Archive_Junction__c junction = new Account_Contract_Archive_Junction__c();
        junction.Account__c = opportunity.AccountId;
        junction.Contract_Archive__c = archiveId;
        junction.Internal_Contract_Number__c =internalContractNumber;
        junction.Account_Contract_Archive_Junction_Sys_Id__c = relationship_sys_id;
        insert junction;
        return junction;
    }

    private static void assignContractSysId(OuterWrapper outerWrapper ) {
        contract_sys_id = outerWrapper.result.contract_sys_id;
        internal_contract_number = outerWrapper.result.internal_contract_number;
        relationship_sys_id = outerWrapper.result.relationship_sys_id;
    }

    private static void updateOpportunity(String archiveId, String junctionId, String callOffId){
        if(archiveId != null){
            opportunity.Contract_Lookup__c = archiveId;
        }
        if(junctionId != null){
            opportunity.Account_Contract_Archive_Junction__c = junctionId;
        }
        if(calloffId != null){
            opportunity.Call_Off_Contract__c = callOffId;
        }
        opportunity.UploadTime__c = Datetime.now();
        opportunity.IsContractSent__c = true;
        update opportunity;
    }

    private static OuterWrapper deserializeResponse(HttpResponse response){
        return (OuterWrapper) JSON.deserialize(response.getBody(), OuterWrapper.class);
    }


    public virtual class NewContractBody{
        String opportunity_salesforce_id;
        String customer_contract_name;
        String opportunity_creator;
        String customer_contract_number;


        public NewContractBody(String opportunity_salesforce_id,String customer_contract_name, String opportunity_creator, String customer_contract_number) {
            this.opportunity_salesforce_id = opportunity_salesforce_id;
            this.customer_contract_name = customer_contract_name;
            this.opportunity_creator = opportunity_creator;
            this.customer_contract_number = customer_contract_number;
        }
    }

    public class UpdateExistingContractBody extends NewContractBody {
        String contract_sys_id;
        String archive_name;
        String archive_number;
        String sub_area;

        public UpdateExistingContractBody(String contract_sys_id, String opportunity_salesforce_id,String archive_name,String archive_number,String sub_area,String customer_contract_name,String customer_contract_number) {
            super(opportunity_salesforce_id,customer_contract_name,null,customer_contract_number);
            this.contract_sys_id = contract_sys_id;
            this.archive_name = archive_name;
            this.archive_number = archive_number;
            this.sub_area = sub_area;

        }
    }

    public virtual class AttachmentNewContractBody {
        String contract_sys_id;
        List<Attachment> attachments;
        String opportunity_owner;
        String contract_category;
        String comment;
        String customer_contract_name;
        String customer_contract_number;

        public AttachmentNewContractBody(String contract_sys_id, List<Attachment> attachments,String opportunity_owner,String comment, String contract_category,String customer_contract_name, String customer_contract_number) {
            this.contract_sys_id = contract_sys_id;
            this.attachments = attachments;
            this.opportunity_owner = opportunity_owner;
            this.contract_category = contract_category;
            this.customer_contract_name = customer_contract_name;
            this.customer_contract_number = customer_contract_number;
            this.comment = comment;
        }
    }

    public class AttachmentExistingContractBody extends AttachmentNewContractBody {
        String opportunity_salesforce_id;
        String call_off_sys_id;
        String sub_area;

        public AttachmentExistingContractBody(String opportunity_salesforce_id,String contract_sys_id,List<Attachment> attachments,String call_off_sys_id,String opportunity_owner,String comment, String sub_area, String contract_category,String customer_contract_name, String customer_contract_number) {
            super(contract_sys_id,attachments,opportunity_owner,comment,contract_category,customer_contract_name,customer_contract_number);
            this.opportunity_salesforce_id = opportunity_salesforce_id;
            this.call_off_sys_id = call_off_sys_id;
            this.sub_area = sub_area;
        }
    }

    public class Attachment {
        String file_name;
        String content_type;
        String base64_content;

        public Attachment(String file_name, String base64_content,String content_type) {
            this.file_name = file_name;
            this.content_type = content_type;
            this.base64_content = base64_content;
        }
    }

    public class OuterWrapper {
        @AuraEnabled
        public ResponseWrapper result;
    }

    public class ResponseWrapper{
        @AuraEnabled
        public String result;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public String contract_sys_id;
        @AuraEnabled
        public String internal_contract_number;
        @AuraEnabled
        public String task_sys_id;
        @AuraEnabled
        public String task_number;
        @AuraEnabled
        public String relationship_sys_id;
    }
}