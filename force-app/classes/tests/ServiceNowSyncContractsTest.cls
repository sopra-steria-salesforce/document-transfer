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

        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody('{ "result": [ { "identification_number": null, "customer_contract_name": "test21", "internal_contract_number": "AGR0003720", "customer_contract_number": "test21", "contract_type": "", "total_value": "kr 0,00", "parent_agreement": "", "parent_archive": "", "contract_state": "draft", "contract_signed": "at_risk", "contract_billing_status": "", "primary_customer": "1638fdb887e13550f2c2ed390cbb3552", "are_we_subcontractor_in_this_contract": "", "broker_agreement": "false", "legal_owner": "ccbb57d41b4e9990425c639ce54bcb81", "business_unit": null, "business_unit_name": "", "region": null, "group": "", "subcontractor_delivers_in_agreement": "false", "contract_approved": "true", "approved_comment": "", "agreement_has_valid_call_offs": "false", "pending_in_department_task": "false", "projects": null, "resources": "", "opportunity": "", "sign_date": "", "start_date": "", "notice_period_sopra_steria_in_month": "", "initial_date_of_expiry": "", "final_date_of_expiry": "", "final_expiration_confirmed": "false", "no_expiry_date": "false", "notice_period_customer_in_month": "", "can_be_extended": "false", "extension_model": null, "extend_to": "", "notification_before_expiry_months_before": "", "max_extension_years": "", "years_at_a_time": null, "extension_reason": null, "price_adjustment_enable": "", "price_index": null, "describe_index": null, "price_adjustment_date": "", "deadline_for_notifying_customer": null, "customer_notified": "no", "customer_last_notified_on": "", "last_price_adjustment": "", "price_adjustment_on_call_offs": null, "initial_period_from": "", "initial_period_to": "", "next_period_from": "", "next_period_to": "", "last_adjustment_factor": "", "price_model": "price_matrix", "fast_hourly_rate": "kr 0,00", "max_value": "kr 0,00", "max_value_ex_mva": "0", "max_value_ex_mva_currency": "NOK", "price_discount": "false", "price_discount_description": "", "max_hours": null, "admin_fee": "kr 0,00", "po_io_comment": "", "contract_owner": null, "manager_of_contract": "de8125fe871e59501b9e98683cbb35f2", "signed_by": null, "customer_contract_admin": "", "salesforce_account_owner": "", "salesforce_apps_owner": "", "salesforce_bc_owner": "", "salesforce_dps_owner": "", "contact_name": "", "contact_name_2": "", "contact_phone": "", "contact_phone_2": "", "contact_role": "", "contact_role_2": "", "contact_email": "", "contact_email_2": "", "do_we_use_subcontractors_in_this_contract": "false", "choose_subcontractors": "", "comment": "", "sys_created_by": "srv_salesforce_rest_user", "sys_created_on": "2024-10-15 07:50:48", "sys_id": "test", "sys_updated_by": "srv_salesforce_rest_user", "sys_updated_on": "2024-10-15 07:50:49" }, { "identification_number": null, "customer_contract_name": "test210", "internal_contract_number": "AGR0003722", "customer_contract_number": "test210", "contract_type": "Agreement", "total_value": "kr 0,00", "parent_agreement": "", "parent_archive": "", "contract_state": "active", "contract_signed": "yes", "contract_billing_status": "", "primary_customer": "69a77db487e13550f2c2ed390cbb356b", "are_we_subcontractor_in_this_contract": "", "broker_agreement": "false", "legal_owner": "50260356db68e4106f361ded0b961953", "business_unit": "bfb6fdcd8798551078aacb790cbb35f8", "business_unit_name": "Applications", "region": null, "group": "", "subcontractor_delivers_in_agreement": "false", "contract_approved": "true", "approved_comment": "", "agreement_has_valid_call_offs": "false", "pending_in_department_task": "false", "projects": null, "resources": "", "opportunity": "", "sign_date": "", "start_date": "2024-10-10", "notice_period_sopra_steria_in_month": "", "initial_date_of_expiry": "2024-10-27", "final_date_of_expiry": "2024-10-27", "final_expiration_confirmed": "false", "no_expiry_date": "false", "notice_period_customer_in_month": "2", "can_be_extended": "false", "extension_model": null, "extend_to": "", "notification_before_expiry_months_before": "", "max_extension_years": "", "years_at_a_time": null, "extension_reason": null, "price_adjustment_enable": "", "price_index": null, "describe_index": null, "price_adjustment_date": "", "deadline_for_notifying_customer": null, "customer_notified": "no", "customer_last_notified_on": "", "last_price_adjustment": "", "price_adjustment_on_call_offs": null, "initial_period_from": "", "initial_period_to": "", "next_period_from": "", "next_period_to": "", "last_adjustment_factor": "", "price_model": "price_matrix", "fast_hourly_rate": "kr 0,00", "max_value": "kr 0,00", "max_value_ex_mva": "0", "max_value_ex_mva_currency": "NOK", "price_discount": "false", "price_discount_description": "", "max_hours": null, "admin_fee": "kr 0,00", "po_io_comment": "", "contract_owner": null, "manager_of_contract": "08a33d1adbb960107741a28bd39619a9", "signed_by": null, "customer_contract_admin": "", "salesforce_account_owner": "", "salesforce_apps_owner": "", "salesforce_bc_owner": "", "salesforce_dps_owner": "", "contact_name": "", "contact_name_2": "", "contact_phone": "", "contact_phone_2": "", "contact_role": "", "contact_role_2": "", "contact_email": "111", "contact_email_2": "", "do_we_use_subcontractors_in_this_contract": "false", "choose_subcontractors": "", "comment": "", "sys_created_by": "srv_salesforce_rest_user", "sys_created_on": "2024-10-15 08:32:48", "sys_id": "28db900dc3d19610f1b4b9bf0501312d", "sys_updated_by": "mona.wilhelmsen@soprasteria.com", "sys_updated_on": "2024-10-15 09:07:10" }]}');
        response.setHeader('Content-Type', 'application/json');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ServiceNowSyncContractsMock(response));
        ServiceNowSyncContractArchiveRecords.syncContractArchiveRecords();
        Test.stopTest();
    }

    public class ServiceNowSyncContractsMock implements HttpCalloutMock {
        HttpResponse response;

        public ServiceNowSyncContractsMock(HttpResponse response) {
            this.response = response;
        }

        public HttpResponse respond(HttpRequest request) {
            return response;
        }
    }
}