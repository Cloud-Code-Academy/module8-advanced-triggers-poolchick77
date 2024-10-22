public with sharing class OpportunityHelper {
    List<Opportunity> triggerList = new List<Opportunity>();
    Map<Id, Opportunity> triggerMap = new Map<Id, Opportunity>();

    public OpportunityHelper(List<Opportunity> triggerList){
        this.triggerList = triggerList;
    }

    public OpportunityHelper(Map<Id, Opportunity> triggerMap){
        this.triggerMap = triggerMap;
    }
    

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
    public void assignPrimaryContact() {        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : triggerMap.values()){
            if(opp.Primary_Contact__c == null && opp.AccountId != null){
                accountIds.add(opp.AccountId);
            }
        }
        Map<Id, Contact> primaryContactMap = new Map<Id, Contact>();     
        for (Contact contact : [SELECT Id, AccountId FROM Contact WHERE Title = 'VP Sales' AND AccountId IN :accountIds])  {
            primaryContactMap.put(contact.AccountId, contact);
        } 

        for (Opportunity opp : triggerMap.values()){            
            if (opp.Primary_Contact__c == null){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = primaryContactMap.get(opp.AccountId).Id;
                oppMap.put(opp.Id, oppToUpdate);
            }
        }
        update oppMap.values();
    }

    public void amountValidation(){
        for(Opportunity opp : triggerList){
            if(opp.Amount <= 5000){
                opp.addError('Opportunity amount must be greater than 5000');
                        
            }

        }
    }

    public void setPrimaryContact(){
        List<Id> accountIds = new List<Id>();
            for (Opportunity opp : triggerList) {
                if (opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
            }
            
            Map<Id, Contact> ceoContactsByAccount = new Map<Id, Contact> ([SELECT Id, AccountId, Title FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO']);
            system.debug(ceoContactsByAccount);
            Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();
            for (Contact cont : ceoContactsByAccount.values()) {
                accountIdToContact.put(cont.AccountId, cont);
            }
            for(Opportunity opp : triggerList){
            opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
            }
        }

    public void updateDescriptionFromStage(){

            for(Opportunity opp : triggerList){
                system.debug('we are on line 96');
                opp.Description += 'Stage Change:' + opp.StageName;
            }
        }
    
    public void setDefaultOpportunityType(){
        for(Opportunity opp : triggerList){
            if (opp.Type == null){
                opp.Type = 'New Customer';
                }        
            } 
    }

    public void insertTask(){
        List<Task> tskList = new List<Task>();
        for (Opportunity opp : triggerList){
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

    public void deleteCloseWonOpportunity(){
        List<Id> accIdList = new List<Id>();
        for(Opportunity oldOpp : triggerList){
            accIdList.add(oldOpp.AccountId);
        }
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN :accIdList]);
        for (Opportunity oldOpp : triggerList){
            if (oldOpp.StageName == 'Closed Won' && accounts.get(oldOpp.AccountId).Industry == 'Banking'){
                oldOpp.addError('Cannot delete closed opportunity');
            }

       }
    }

    public void validateCloseOpportunity(){
        for(Opportunity opp : triggerList){
            if (opp.IsClosed){
            opp.addError('Cannot delete closed opportunity');
            }
        }                        
    }
}
