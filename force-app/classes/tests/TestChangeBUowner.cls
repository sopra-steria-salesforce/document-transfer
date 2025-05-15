@isTest
public class TestChangeBUowner {
  public static List<User> getUsers = [
    SELECT Business_Unit__c, IsActive
    FROM User
    WHERE Email LIKE '%test@example.com%' AND Alias LIKE '%testu%'
    LIMIT 2
  ];
  public static List<User> updateUsers = new List<User>();
  public static Integer opps;
  public static Integer accounts;

  @testSetup
  static void setup() {
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    // Insert account as current user

    System.runAs(thisUser) {
      TestDataFactory.createOpportunities(50);
      TestDataFactory.createAccounts(50);
      TestDataFactory.createUsers(3);
    }
  }
  //*************** ACCOUNTS *************/

  @isTest
  static void appsAccountTest() {
    accounts = TestChangeBUOwnerUtil.businessUnitAccountTest();
    System.assertEquals(51, accounts, 'accounts should equal 50');
  }

  @isTest
  static void advisoryAccountTest() {
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    // Insert account as current user
    System.debug('getusers' + getUsers);
    System.runAs(thisUser) {
      for (User u : getUsers) {
        System.debug('i am inside the forloop' + Utils.ADVISORY);
        u.Business_Unit__c = Utils.Advisory;
        u.IsActive = true;
        updateUsers.add(u);
      }
      update updateUsers;
      System.debug(updateUsers);
      accounts = TestChangeBUOwnerUtil.businessUnitAccountTest();
    }
    System.assertEquals(51, accounts, 'accounts should equal 50');
  }

  @isTest
  static void dpsAccountTest() {
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    // Insert account as current user
    System.runAs(thisUser) {
      for (User u : getUsers) {
        u.Business_Unit__c = Utils.DPS;
        u.IsActive = true;
        updateUsers.add(u);
      }
      update updateUsers;
      accounts = TestChangeBUOwnerUtil.businessUnitAccountTest();
    }
    System.assertEquals(51, accounts, 'accounts should equal 50');
  }
  @isTest
  static void bulkAccountTest() {
    TestDataFactory.createAccounts(149);
    accounts = TestChangeBUOwnerUtil.businessUnitAccountTest();
    System.assertEquals(200, accounts, 'accounts should equal 200');
  }
  //********** OPPORTUNITIES **************/
  @isTest
  static void appsOppTest() {
    opps = TestChangeBUOwnerUtil.businessUnitOpportunityTest();
    System.assertEquals(50, opps, 'opps should equal 50');
  }

  @isTest
  static void dpsOppTest() {
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    // Insert account as current user
    System.runAs(thisUser) {
      for (User u : getUsers) {
        u.Business_Unit__c = Utils.DPS;
        u.isActive = true;
        updateUsers.add(u);
      }
      update updateUsers;
      opps = TestChangeBUOwnerUtil.businessUnitOpportunityTest();
    }
    System.assertEquals(50, opps, 'opps should equal 50');
  }
  @isTest
  static void threeUsersOppTest() {
    opps = TestChangeBUOwnerUtil.thirdUserTest();
    System.assertEquals(25, opps, 'opps should equal 25');
  }
  @isTest
  static void openOppsTest() {
    opps = TestChangeBUOwnerUtil.openOppsTest();
    System.assertEquals(25, opps, 'opps should equal 25');
  }
}