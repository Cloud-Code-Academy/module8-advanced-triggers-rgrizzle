public with sharing class OpportunityHelper {
    public OpportunityHelper() {

    }

    public static void amountValidation (List<Opportunity> opps) {
        for (Opportunity o : opps) {
            if(o.Amount < 5000){
                o.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

   public static void cantDeleteCWOppOnBankingAcct(List<Opportunity> opps) {
    // Step 1: Collect banking account IDs and closed-won opportunity IDs
    Set<Id> bankingAccountIds = new Set<Id>();
    Set<Id> closedWonOppIds = new Set<Id>();

    for (Opportunity o : opps) {
        Opportunity newOpp = new Opportunity(Id = o.Id);
        newOpp.addError('Cannot delete closed opportunity');
    }

  /* System.debug('Opps::: '+ opps);
   if (opps == null) {
    System.debug('The provided list of Opportunities is null.');
    return;
   }

   Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>(
   [SELECT Id, IsWon, AccountId, Account.Industry FROM Opportunity WHERE Id IN :opps]
   );


    for (Opportunity o : oppMap.values()) {
        System.debug('o.Account.Industry::: ' + o.Account.Industry);
        if (o.Account != null && o.Account.Industry == 'Banking') {
            bankingAccountIds.add(o.AccountId);
        }
        if (o.IsWon) {
            closedWonOppIds.add(o.Id);
        }
    }
    System.debug('Banking Account Ids::: ' + bankingAccountIds);
    // Step 2: Query and validate opportunities
    List<Opportunity> invalidOpps = [SELECT Id FROM Opportunity
                                     WHERE AccountId IN :bankingAccountIds
                                       AND Id IN :closedWonOppIds];

    // Step 3: Set error messages for invalid opportunities
    System.debug('Invalid Opps::: ' + invalidOpps);
    for (Opportunity o : invalidOpps) {
        System.debug(o.Id);
        Opportunity opp = new Opportunity(Id = o.Id); // Need a new instance to add error
        opp.addError('Cannot delete closed opportunity');
    }*/
   } 
   

    public static void makeCEOPrimaryConact(List<Opportunity> opps) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity o : opps) {
            accountIds.add(o.AccountId);
        }

        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
        Map<Id, Contact> accountIdToConact = new Map<Id, Contact>();

        for (Contact c : contacts.values()) {
            if (!accountIdToConact.containsKey(c.AccountId)) {
                accountIdToConact.put(c.AccountId, c);
            }
        }

        for (Opportunity opp : opps) {
            if (opp.Primary_Contact__c == null) {
                if (accountIdToConact.containsKey(opp.AccountId)) {
                    opp.Primary_Contact__c = accountIdToConact.get(opp.AccountId).Id;
                }
            }
        }
    }
    

    public static void assignPrimaryContact(Map<Id, Opportunity> newOppMap) {
        Set<Id> accIdSet = new Set<Id>();
    
        // Collect account IDs from the provided opportunities
        for (Opportunity opp : newOppMap.values()) {
            accIdSet.add(opp.AccountId);
        }
    
        // Query accounts with related VP Sales contacts
        Map<Id, Account> accountIdToAccountWithVP = new Map<Id, Account>([
            SELECT Id, 
                   (SELECT Id FROM Contacts WHERE Title = 'VP Sales' LIMIT 1)
            FROM Account
            WHERE Id IN :accIdSet
        ]);
    
        // Prepare list of opportunities to update
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
    
        // Assign primary contact for each opportunity
        for (Opportunity opp : newOppMap.values()) {
            Account acc = accountIdToAccountWithVP.get(opp.AccountId);
            if (acc != null && !acc.Contacts.isEmpty()) {
                // Retrieve the first VP Sales contact for the account
                Contact primaryContact = acc.Contacts[0];
                if (opp.Primary_Contact__c == null) {
                    // Create a new instance of Opportunity to update
                    Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                    oppToUpdate.Primary_Contact__c = primaryContact.Id;
                    oppsToUpdate.add(oppToUpdate);
                }
            }
        }
    
        // Update the list of opportunities
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }
    

    public static void insertTask(List<Opportunity> opps) {
        List<Task> tasksToInsert = new List<Task>();
        for (Opportunity o : opps) {
            Task tsk = new Task();
            tsk.Subject = 'Call Primary Contact';
            tsk.WhatId = o.Id;
            tsk.WhoId = o.Primary_Contact__c;
            tsk.OwnerId = o.OwnerId;
            tsk.ActivityDate = Date.today().addDays(3);
            tasksToInsert.add(tsk);
        }
        insert tasksToInsert;
    }

    public static void setOppType(List<Opportunity> opps) {
        for (Opportunity o : opps) {
            if (o.Type == null) {
                o.Type = 'New Customer';
            }
        }

    }

    public static void updateDescriptionFromStage(List<Opportunity> opps, Map<Id, Opportunity> newOppMap, Map<Id,Opportunity> oldOppMap) {
        for (Opportunity o : opps) {
            Opportunity oldOpp = oldOppMap.get(o.Id);
            if (o.StageName != oldOpp.StageName) {
                o.Description += '\n Stage Change:' + o.StageName + ':' + Datetime.now().format();
            }
        }
    }

    public static void validateCloseOpportunities(List<Opportunity> opps) {
        for (Opportunity o : opps) {
                if (o.IsClosed) {
                    o.addError('Cannot delete closed opportunity');
                }
        }
    }

    public static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Id> oppOwnerIds = new List<Id>();
        for (Opportunity o : opps) {
            oppOwnerIds.add(o.OwnerId);
        }

        Map<Id, User> oppIdsToUsers = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :oppOwnerIds]);

        for (Opportunity opp : opps){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {oppIdsToUsers.get(opp.OwnerId).Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }
    

}
