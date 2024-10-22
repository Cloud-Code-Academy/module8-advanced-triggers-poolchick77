public with sharing class OpportunityTriggerHandler extends TriggerHandler {
   
    
    // Set default Type for new Opportunities
    public override void beforeInsert(){
        OpportunityHelper newOpportunityHelper = new OpportunityHelper((List<Opportunity>) trigger.new);
        newOpportunityHelper.setDefaultOpportunityType();
    }
        
    public override void afterInsert(){
        OpportunityHelper newOpportunityHelper = new OpportunityHelper((List<Opportunity>) trigger.new);
        newOpportunityHelper.insertTask();
    }


    /*
    * Opportunity Trigger
    * When an opportunity is updated set the primary contact on the opportunity to the contact with the title of 'CEO'.
    * When an opportunity is updated validate that the amount is greater than 5000.    
    * Append Stage changes in Opportunity Description
    * Trigger should only fire on update.
    */
    public override void beforeUpdate(){
        
        OpportunityHelper newOpportunityHelper = new OpportunityHelper((List<Opportunity>) trigger.new);
        newOpportunityHelper.setPrimaryContact();
        newOpportunityHelper.amountValidation();
        newOpportunityHelper.updateDescriptionFromStage();
    }
            
    
             
    public override void beforeDelete(){
        OpportunityHelper newOpportunityHelper = new OpportunityHelper((List<Opportunity>) trigger.old);
        newOpportunityHelper.deleteCloseWonOpportunity();
        newOpportunityHelper.validateCloseOpportunity();
    }

    public override void afterDelete(){
        OpportunityHelper newOpportunityHelper = new OpportunityHelper((List<Opportunity>) trigger.old);
        OpportunityHelper.notifyOwnersOpportunityDeleted(trigger.old);
    }
    
    public override void afterUndelete(){
        TriggerHandler.bypass('OpportunityTriggerHandler');
        OpportunityHelper newOpportunityHelper = new OpportunityHelper((Map<Id, Opportunity>) trigger.newMap);
        newOpportunityHelper.assignPrimaryContact();
    
    }
    
}



  




    