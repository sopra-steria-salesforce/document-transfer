public with sharing class TestingUtils {

	/**
	 * @description: Needed because SF doesn't support assigning existing Permission Sets in Test Context (Custom permissions are not calculated wrt. running user sharing access)
	 * See https://www.jamessimone.net/blog/joys-of-apex/testing-custom-permissions/
	 */
	public static void activateCustomPermission(Id userId, String permissionName){
		PermissionSet serviceNowContractUpsertTesting = new PermissionSet(
			Name='DummyPSfortesting',
			Label='Dummy PS for testing'
		);
		insert serviceNowContractUpsertTesting;

		SetupEntityAccess setupEntityAccess = new SetupEntityAccess(
				ParentId=serviceNowContractUpsertTesting.Id,
				SetupEntityId=[
						SELECT Id
						FROM CustomPermission
						WHERE DeveloperName=:permissionName
						LIMIT 1
				].Id
		);
		PermissionSetAssignment permissionSetAssignment=new PermissionSetAssignment(
				AssigneeId=userId,
				PermissionSetId=serviceNowContractUpsertTesting.Id

		);
		insert new List<SObject>{setupEntityAccess, permissionSetAssignment};
	}
}