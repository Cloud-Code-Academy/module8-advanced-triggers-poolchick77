public with sharing class OpportunityTriggerHandler extends TriggerHandler {
   
    
    // Set default Type for new Opportunities
    public override void beforeInsert(){
   
        OpportunityHelper.setDefaultOpportunityType((List<Opportunity>) trigger.new);
    }
        
    public override void afterInsert(){
        
        OpportunityHelper.insertTask((List<Opportunity>) trigger.new);
    }


    /*
    * Opportunity Trigger
    * When an opportunity is updated set the primary contact on the opportunity to the contact with the title of 'CEO'.
    * When an opportunity is updated validate that the amount is greater than 5000.    
    * Append Stage changes in Opportunity Description
    * Trigger should only fire on update.
    */
    public override void beforeUpdate(){
        
        OpportunityHelper.setPrimaryContact((List<Opportunity>) trigger.new);
        OpportunityHelper.amountValidation((List<Opportunity>) trigger.new);
        OpportunityHelper.updateDescriptionFromStage((List<Opportunity>) trigger.new);
    }
            
    
             
    public override void beforeDelete(){
        
        OpportunityHelper.deleteCloseWonOpportunity((List<Opportunity>) trigger.old);
        OpportunityHelper.validateCloseOpportunity((List<Opportunity>) trigger.old);
    }

    public override void afterDelete(){
        OpportunityHelper.notifyOwnersOpportunityDeleted((List<Opportunity>) trigger.old);
    }
    
    public override void afterUndelete(){
        TriggerHandler.bypass('OpportunityTriggerHandler');
        OpportunityHelper.assignPrimaryContact((List<Opportunity>) trigger.new, (Map<Id, Opportunity>) trigger.newMap);
    
    }
    
}



  




    