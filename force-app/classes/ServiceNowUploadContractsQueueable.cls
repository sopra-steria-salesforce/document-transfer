/**
 * Created by kjachowicz on 20.01.2025.
 */

public with sharing class ServiceNowUploadContractsQueueable implements Queueable, Database.AllowsCallouts {
  private Opportunity opportunity;
  static String contract_sys_id;
  static String internal_contract_number;
  static String relationship_sys_id;
  static String task_sys_id;
  static String task_number;
  static String url;
  static Map<String, String> country2LegalOwner = new Map<String, String>{
    'Norway' => 'Sopra Steria Norway',
    'Sweden' => 'Sopra Steria Sweden',
    'Denmark' => 'Sopra Steria Denmark'
  };
  static String truncatedUsername;
  public static Boolean isContractUploadProcessStarted = false;

  public ServiceNowUploadContractsQueueable(Opportunity opportunity) {
    this.opportunity = opportunity;
  }
  public void execute(QueueableContext param1) {
  
    System.debug(opportunity);
    isContractUploadProcessStarted = true;
    truncatedUsername = [
        SELECT Id, Owner.Username
        FROM Opportunity
        WHERE Id = :opportunity.Id
      ]
      .Owner.Username.replace('.uat', '');

    try {
      if (
        opportunity.Contract_Category__c ==
        'New contract (not connected to framework/capacity agreement)'
      ) {
        uploadNewContract(opportunity);
      } else if (
        opportunity.Contract_Category__c ==
        'Change to an active call off or contract' ||
        opportunity.Contract_Category__c ==
        'New call off (Agreement on existing contract)'
      ) {
        uploadExistingContract(opportunity);
      }
    } catch (Exception ex) {
      // Log to Application_Log__c using the existing method
      Utils.logFailure('ServiceNowUploadContractsQueueable', 'uploadContracts', ex.getMessage(),'Failed',UserInfo.getUserName(),'Exception occurred during contract upload. Opportunity Id: ' +opportunity.Id + '\n' +ex.getStackTraceString()
      );

      // Throw appropriate exception based on context
      if (System.isBatch() || System.isQueueable() || System.isFuture()) {
        throw new ContractUploadException(ex.getMessage());
      } else {
        throw new AuraHandledException(ex.getMessage());
      }
    }
  }

  private static void uploadNewContract(Opportunity opportunity) {
    OuterWrapper outerWrapper = createNewContracts(opportunity);
    Contract_Archive__c archive = createNewContractArchive(opportunity);
    Account_Contract_Archive_Junction__c junction = createJunction(
      archive.Id,
      internal_contract_number,
      opportunity
    );
    updateOpportunity(archive.Id, junction.Id, null, opportunity, outerWrapper);
  }

  private static void uploadExistingContract(Opportunity opportunity) {
    OuterWrapper outerWrapper = createExistingContracts(opportunity);
    Call_Off_Contract__c callOff = createCallOff(opportunity, outerWrapper);
    updateOpportunity(
      null,
      null,
      calloff != null ? callOff.Id : null,
      opportunity,
      outerWrapper
    );
  }

  private static NewContractBody prepareBodyForCreateNewContracts(
    Opportunity opportunity
  ) {
    NewContractBody requestBody = new NewContractBody(
      opportunity.Id,
      opportunity.Contract_Category__c,
      truncatedUsername
    );
    return requestBody;
  }

  private static UpdateExistingContractBody prepareBodyForCreateExistingContracts(
    Opportunity opportunity
  ) {
    Opportunity currentOpportunity = [
      SELECT Id, Contract_Lookup__r.Sys_Id_External__c
      FROM Opportunity
      WHERE Id = :opportunity.Id
    ];
    UpdateExistingContractBody requestBody = new UpdateExistingContractBody(
      opportunity.Id,
      opportunity.Contract_Category__c,
      truncatedUsername,
      currentOpportunity.Contract_Lookup__r.Sys_Id_External__c,
      String.isNotBlank(opportunity.Sub_Area__c) ? opportunity.Sub_Area__c : ''
    );
    return requestBody;
  }

  private static OuterWrapper createExistingContracts(Opportunity opportunity) {
    try {
      HttpResponse response = Utils.doRequest(
        Utils.NAMED_CREDENTIAL_SERVICE_NOW,
        Utils.API_UPDATE_EXISTING_CONTRACTS,
        Utils.METHOD_PATCH,
        JSON.serialize(prepareBodyForCreateExistingContracts(opportunity))
      );
      if (response.getStatusCode() == 200) {
        OuterWrapper outerWrapper = deserializeResponse(response);
        assignValuesFromRequest(outerWrapper);
        return outerWrapper;
      }
    } catch (Exception e) {
      Utils.logFailure(
        'ServiceNowUploadContracts',
        'createExistingContracts',
        e.getMessage(),
        'Failed',
        UserInfo.getUserName(),
        'Exception occurred during API call'
      );
    }
    return null;
  }

  private static OuterWrapper createNewContracts(Opportunity opportunity) {
    try {
      HttpResponse response = Utils.doRequest(
        Utils.NAMED_CREDENTIAL_SERVICE_NOW,
        Utils.API_CREATE_NEW_CONTRACTS,
        Utils.METHOD_POST,
        JSON.serialize(prepareBodyForCreateNewContracts(opportunity))
      );
      if (response.getStatusCode() == 200) {
        OuterWrapper outerWrapper = deserializeResponse(response);
        assignContractSysId(outerWrapper);
        return outerWrapper;
      }
    } catch (Exception e) {
      Utils.logFailure(
        'ServiceNowUploadContracts',
        'createNewContracts',
        e.getMessage(),
        'Failed',
        UserInfo.getUserName(),
        'Exception occurred during API call'
      );
    }
    return null;
  }

  private static Call_Off_Contract__c createCallOff(
    Opportunity opportunity,
    OuterWrapper outerWrapper
  ) {
    if (
      opportunity.Contract_Category__c ==
      'New call off (Agreement on existing contract)'
    ) {
      Call_Off_Contract__c callOff = new Call_Off_Contract__c();
      callOff.Sys_Id_External__c = task_sys_id;
      callOff.Name = opportunity.Name.length() > 70 ? opportunity.Name.substring(0,69) : opportunity.Name;
      callOff.Parent_Contract__c = opportunity.Contract_Lookup__c;
      callOff.Number__c = task_number;
      callOff.Account__c = opportunity.AccountId;
      insert callOff;
      return callOff;
    } else {
      return null;
    }
  }

  private static Contract_Archive__c createNewContractArchive(
    Opportunity opportunity
  ) {
    Contract_Archive__c archive = new Contract_Archive__c();
    User currentUser = [
      SELECT Id, Country
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];
    archive.LegalOwner__c = country2LegalOwner.get(currentUser.Country);
    archive.Name = opportunity.Name.length() > 79 ? opportunity.Name.substring(0,79) : opportunity.Name;
    archive.Sys_Id_External__c = contract_sys_id;
    archive.Internal_Contract_Number__c = internal_contract_number;
    archive.Primary_Customer__c = opportunity.AccountId;
    insert archive;
    return archive;
  }

  private static Account_Contract_Archive_Junction__c createJunction(
    Id archiveId,
    String internalContractNumber,
    Opportunity opportunity
  ) {
    Account_Contract_Archive_Junction__c junction = new Account_Contract_Archive_Junction__c();
    junction.Account__c = opportunity.AccountId;
    junction.Contract_Archive__c = archiveId;
    junction.Internal_Contract_Number__c = internalContractNumber;
    junction.Account_Contract_Archive_Junction_Sys_Id__c = relationship_sys_id;
    insert junction;
    return junction;
  }

  private static void assignContractSysId(OuterWrapper outerWrapper) {
    contract_sys_id = outerWrapper.result.contract_sys_id;
    internal_contract_number = outerWrapper.result.internal_contract_number;
    relationship_sys_id = outerWrapper.result.relationship_sys_id;
    url = outerWrapper.result.url;
  }

  private static void assignValuesFromRequest(OuterWrapper outerWrapper) {
    task_sys_id = outerWrapper.result.task_sys_id;
    task_number = outerWrapper.result.task_number;
    url = outerWrapper.result.url;
  }

  private static void updateOpportunity(
    String archiveId,
    String junctionId,
    String callOffId,
    Opportunity opportunity,
    OuterWrapper outerWrapper
  ) {
    if (archiveId != null) {
      opportunity.Contract_Lookup__c = archiveId;
    }
    if (junctionId != null) {
      opportunity.Account_Contract_Archive_Junction__c = junctionId;
    }
    if (calloffId != null) {
      opportunity.Call_Off_Contract__c = callOffId;
    }
    opportunity.UploadTime__c = Datetime.now();
    opportunity.IsContractSent__c = true;
    opportunity.ContractServiceNowUrl__c = url;
    update opportunity;
  }

  private static OuterWrapper deserializeResponse(HttpResponse response) {
    return (OuterWrapper) JSON.deserialize(
      response.getBody(),
      OuterWrapper.class
    );
  }

  public virtual class NewContractBody {
    String opportunity_salesforce_id;
    String opportunity_creator;
    String contract_category;

    public NewContractBody(
      String opportunity_salesforce_id,
      String contract_category,
      String opportunity_creator
    ) {
      this.opportunity_salesforce_id = opportunity_salesforce_id;
      this.contract_category = contract_category;
      this.opportunity_creator = opportunity_creator;
    }
  }

  public class UpdateExistingContractBody extends NewContractBody {
    String contract_sys_id;
    String sub_area;

    public UpdateExistingContractBody(
      String opportunity_salesforce_id,
      String contract_category,
      String opportunity_creator,
      String contract_sys_id,
      String sub_area
    ) {
      super(opportunity_salesforce_id, contract_category, opportunity_creator);
      this.contract_sys_id = contract_sys_id;
      this.sub_area = sub_area;
    }
  }

  public class OuterWrapper {
    public ResponseWrapper result;
  }
  public class ResponseWrapper {
    public String result;
    public String message;
    public String contract_sys_id;
    public String internal_contract_number;
    public String relationship_sys_id;
    public String url;
    public String task_number;
    public String task_sys_id;
  }

  // Add custom exception class
  public class ContractUploadException extends Exception {
  }
}