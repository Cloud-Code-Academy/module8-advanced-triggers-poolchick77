public with sharing class OpportunityHelper {
    
    
         /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */
     
        public static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            Set<Id> ownerIds = new Set<Id>();
            for (Opportunity opp: opps) {
                ownerIds.add(opp.OwnerId);
            }

            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :ownerIds]);
            

            for (Opportunity opp : opps){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] {userMap.get(opp.OwnerId).Email});
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
    // assignPrimaryContact:
    // - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    // - Only updates the Opportunities that don't already have a primary contact.
    // */
    public static void assignPrimaryContact(List<Opportunity> oppList, Map<Id, Opportunity> oppMap) {        
        Map<Id, Opportunity> oppMapToUpdate = new Map<Id, Opportunity>();
        Set<Id> accountIds = new Set<Id>();
            for (Opportunity opp : oppMap.values()){
            if(opp.Primary_Contact__c == null && opp.AccountId != null){
                accountIds.add(opp.AccountId);
            }
        }
        Map<Id, Contact> primaryContactMap = new Map<Id, Contact>();     
        for (Contact contact : [SELECT Id, AccountId FROM Contact WHERE Title = 'VP Sales' AND AccountId IN :accountIds])  {
            primaryContactMap.put(contact.AccountId, contact);
        } 

        for (Opportunity opp : oppMap.values()){            
            if (opp.Primary_Contact__c == null){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = primaryContactMap.get(opp.AccountId).Id;
                oppMapToUpdate.put(opp.Id, oppToUpdate);
            }
        }
        update oppMapToUpdate.values();
    }

    public static void amountValidation(List<Opportunity> oppList){
        for(Opportunity opp : oppList){
            if(opp.Amount <= 5000){
                opp.addError('Opportunity amount must be greater than 5000');
                        
            }

        }
    }

    public static void setPrimaryContact(List<Opportunity> oppList){
        List<Id> accountIds = new List<Id>();
            for (Opportunity opp : oppList) {
                if (opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
            }
            
            Map<Id, Contact> ceoContactsByAccount = new Map<Id, Contact> ([SELECT Id, AccountId, Title FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO']);
           
            Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();
        
                for (Contact cont : ceoContactsByAccount.values()) {
                    accountIdToContact.put(cont.AccountId, cont);
                }
                
            for(Opportunity opp : oppList){
                if(opp.Primary_Contact__c == null && accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }

    public static void updateDescriptionFromStage(List<Opportunity> oppList){

        system.debug(oppList);    
        for(Opportunity opp : oppList){
            if(opp.stageName != null){
                system.debug(opp.Description);
                opp.Description += 'Stage Change:' + opp.StageName;
            }
        }
    }
    
    public static void setDefaultOpportunityType(List<Opportunity> oppList){
        for(Opportunity opp : oppList){
            if (opp.Type == null){
                opp.Type = 'New Customer';
                }        
            } 
    }

    public static void insertTask(List<Opportunity> oppList){
        List<Task> tskList = new List<Task>();
        for (Opportunity opp : oppList){
            Task tsk = new Task();
            tsk.Subject = 'Call Primary Contact';
            tsk.WhatId = opp.Id;
            tsk.WhoId = opp.Primary_Contact__c;
            tsk.OwnerId = opp.OwnerId;
            tsk.ActivityDate = Date.today().addDays(3);
            tskList.add(tsk);
        }
        insert tskList;
    
    }

    public static void deleteCloseWonOpportunity(List<Opportunity> oppList){
        List<Id> accIdList = new List<Id>();
        for(Opportunity oldOpp : oppList){
            accIdList.add(oldOpp.AccountId);
        }
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN :accIdList]);
        for (Opportunity oldOpp : oppList){
            if (oldOpp.StageName == 'Closed Won' && accounts.get(oldOpp.AccountId).Industry == 'Banking'){
                oldOpp.addError('Cannot delete closed opportunity');
            }

       }
    }

    public static void validateCloseOpportunity(List<Opportunity> oppList){
        for(Opportunity oldOpp : oppList){
            if (oldOpp.IsClosed){
            oldOpp.addError('Cannot delete closed opportunity');
            }
        }                        
    }
}
