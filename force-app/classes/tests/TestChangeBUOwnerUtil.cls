public with sharing class TestChangeBUOwnerUtil {
  public static User firstUser = [
    SELECT Id, Email, Name, Business_Unit__c
    FROM User
    WHERE
      Email LIKE '%test@example.com%'
      AND Email2__c LIKE '%test@example.com%'
    LIMIT 1
  ];

  public static User secondUser = [
    SELECT Id, Business_Unit__c
    FROM User
    WHERE
      Id != :firstUser.Id
      AND Email LIKE '%test@example.com%'
      AND Email2__c LIKE '%test@example.com%'
    LIMIT 1
  ];

  public static String secondUserId = secondUser.Id;
  public static String businessUnit = secondUser.Business_Unit__c;
  public static String buOwnerField;
  public static String dpsOwnerField = Utils.dps_owner;

  public static Integer businessUnitAccountTest() {
    List<Account> accountsWithInitialBUOwner = new List<Account>();
    List<Account> updatedAccounts = new List<Account>();
    List<Account> accountsWithoutBUOwner = [
      SELECT Id
      FROM Account
    ];

    System.debug('SecondUser.id' + secondUser.id);
    System.debug('FirstUser.id' + firstUser.id);

    //change the accounts to have a BU Owner for their BU
    if (businessUnit == Utils.Apps) {
      for (Account a : accountsWithoutBUOwner) {
        a.put(Utils.apps_Owner, firstUser.id);
        accountsWithInitialBUOwner.add(a);
        buOwnerField = Utils.apps_Owner;
      }
    } else if (businessUnit == Utils.Advisory) {
      System.debug('i am in the forloop for business unit equals Advisory');
      for (Account a : accountsWithoutBUOwner) {
        a.put(Utils.advisory_owner, firstUser.id);
        accountsWithInitialBUOwner.add(a);
        buOwnerField = Utils.advisory_owner;
      }
    } else if (businessUnit == Utils.DPS) {
      for (Account a : accountsWithoutBUOwner) {
        a.put(Utils.dps_owner, firstUser.id);
        accountsWithInitialBUOwner.add(a);
        buOwnerField = Utils.dps_owner;
      }
    } else {
      System.debug(
        'we reached the else statement on giving accounts initial BU Owner'
      );
    }
    System.debug('buowner field:' + buOwnerField);
    update accountsWithInitialBUOwner;
    TestChangeBUOwnerUtil.setupFlowInputs();
    String myQuery = ('SELECT ' +
    buOwnerField +
    ' FROM Account WHERE ' +
    buOwnerField +
    '= :secondUserId');
    System.debug('query inside Account line 62' + myQuery);
    updatedAccounts = Database.query(myQuery);

    return updatedAccounts.size();
  }

  public static Integer businessUnitOpportunityTest() {
    List<Opportunity> oppsWithInitialBUOwner = new List<Opportunity>();
    List<Opportunity> updatedOpps = new List<Opportunity>();
    List<Opportunity> oppsWithoutBUOwner = [
      SELECT Id
      FROM Opportunity
    ];

    //change the opps to have a BU Owner for their BU

    if (businessUnit == Utils.Apps) {
      for (Opportunity a : oppsWithoutBuOwner) {
        a.put(Utils.apps_Owner, firstUser.id);
        oppsWithInitialBUOwner.add(a);
        buOwnerField = Utils.apps_Owner;
      }
    } else if (businessUnit == Utils.Advisory) {
      for (Opportunity a : oppsWithoutBuOwner) {
        a.put(Utils.advisory_Owner, firstUser.id);
        oppsWithInitialBUOwner.add(a);
        buOwnerField = Utils.advisory_owner;
      }
    } else if (businessUnit == Utils.DPS) {
      for (Opportunity a : oppsWithoutBuOwner) {
        a.put(Utils.dps_owner, firstUser.id);
        oppsWithInitialBUOwner.add(a);
        buOwnerField = Utils.dps_owner;
      }
    } else {
      System.debug(
        'we reached the else statement on giving opps initial BU Owner'
      );
    }
    update oppsWithInitialBUOwner;
    TestChangeBUOwnerUtil.setupFlowInputs();
    String myQuery = ('SELECT ' +
    buOwnerField +
    ' FROM Opportunity WHERE ' +
    buOwnerField +
    '= :secondUserId');
    System.debug('query inside testChangeBuOwnerUtil line 108' + myQuery);
    updatedOpps = Database.query(myQuery);

    return updatedOpps.size();
  }

  public static Integer openOppsTest() {
    List<Opportunity> oppsWithInitialBUOwner = new List<Opportunity>();
    List<Opportunity> updatedOpps = new List<Opportunity>();
    List<Opportunity> openOppsToAssignToFirstUser = [
      SELECT Id
      FROM Opportunity
      ORDER BY CreatedDate ASC
      LIMIT 25
    ];
    List<Opportunity> closedOppsToAssignToFirstUser = [
      SELECT Id
      FROM Opportunity
      WHERE Id NOT IN :openOppsToAssignToFirstUser
      ORDER BY CreatedDate ASC
      LIMIT 25
    ];
    for (Opportunity a : openOppsToAssignToFirstUser) {
      a.put(Utils.apps_Owner, firstUser.id);
      oppsWithInitialBUOwner.add(a);
    }
    for (Opportunity a : closedOppsToAssignToFirstUser) {
      a.put(Utils.apps_Owner, firstUser.id);
      a.StageName = 'Closed Lost';
      a.Contract_Category__c = 'New contract (not connected to framework/capacity agreement)';
      oppsWithInitialBUOwner.add(a);
    }
    buOwnerField = Utils.apps_Owner;
    update oppsWithInitialBUOwner;
    TestChangeBUOwnerUtil.setupFlowInputs();
    String myQuery = ('SELECT ' +
    buOwnerField +
    ' FROM Opportunity WHERE ' +
    buOwnerField +
    '= :secondUserId');
    System.debug('query inside testChangeBuOwnerUtil' + myQuery);
    updatedOpps = Database.query(myQuery);

    return updatedOpps.size();
  }

  public static Integer thirdUserTest() {
    List<Opportunity> oppsWithInitialBUOwner = new List<Opportunity>();
    List<Opportunity> updatedOpps = new List<Opportunity>();
    List<Opportunity> oppsToAssignToFirstUser = [
      SELECT Id
      FROM Opportunity
      ORDER BY CreatedDate ASC
      LIMIT 25
    ];
    List<Opportunity> oppsToAssignToThirdUser = [
      SELECT Id
      FROM Opportunity
      WHERE Id NOT IN :oppsToAssignToFirstUser
      LIMIT 25
    ];
    User thirdUser = [
      SELECT Id, Business_Unit__c
      FROM User
      WHERE
        Id != :firstUser.Id
        AND Id != :secondUser.id
        AND Email LIKE '%test@example.com%'
        AND Email2__c LIKE '%test@example.com%'
      LIMIT 1
    ];
    for (Opportunity a : oppsToAssignToFirstUser) {
      a.put(Utils.apps_Owner, firstUser.id);
      oppsWithInitialBUOwner.add(a);
    }
    for (Opportunity a : oppsToAssignToThirdUser) {
      a.put(Utils.apps_Owner, thirdUser.id);
      oppsWithInitialBUOwner.add(a);
    }
    buOwnerField = Utils.apps_Owner;
    update oppsWithInitialBUOwner;
    TestChangeBUOwnerUtil.setupFlowInputs();
    String myQuery = ('SELECT ' +
    buOwnerField +
    ' FROM Opportunity WHERE ' +
    buOwnerField +
    '= :secondUserId');
    System.debug('query inside testChangeBuOwnerUtil line 108' + myQuery);
    updatedOpps = Database.query(myQuery);

    return updatedOpps.size();
  }
  public static void setupFlowInputs() {
    //Set up flow inputs

    List<BUOwner.FlowInputs> input = new List<BUOwner.FlowInputs>();
    BUOwner.FlowInputs flowinputI = new BUOwner.FlowInputs();
    flowinputI.var_currentOwnerId = firstUser.Id;
    flowInputI.var_newOwnerId = secondUser.Id;
    flowInputI.var_BU = businessUnit;
    flowInputI.var_BUOwnerField = buOwnerField;
    input.add(flowinputI);
    Test.startTest();
    //run the class to change all the accounts to the second user
    BUOwner.accountBUOwnerInvoke(input);
    Test.stopTest();
    //check to see that all the accounts were updated
  }
}