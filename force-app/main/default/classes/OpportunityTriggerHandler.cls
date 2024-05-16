public with sharing class OpportunityTriggerHandler extends TriggerHandler{
    public Map<Id, Opportunity> newOppMap;
    public Map<Id, Opportunity> oldOppMap;

    public OpportunityTriggerHandler() {
        this.newOppMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldOppMap = (Map<Id,Opportunity>) Trigger.oldMap;
    }

 

    public override void beforeInsert() {
        OpportunityHelper.setOppType(Trigger.new);
    }

    public override void afterInsert() {
        OpportunityHelper.insertTask(Trigger.new);
    }

    public override void beforeUpdate() {
        OpportunityHelper.makeCEOPrimaryConact(Trigger.new);
        OpportunityHelper.amountValidation(Trigger.new);
        OpportunityHelper.updateDescriptionFromStage(Trigger.new, newOppMap, oldOppMap);
    }

    public override void afterUpdate() {

    }

    public override void beforeDelete() {
        OpportunityHelper.cantDeleteCWOppOnBankingAcct(Trigger.old);
        OpportunityHelper.validateCloseOpportunities(Trigger.old);
       
        
    }

    public override void afterDelete() {
    OpportunityHelper.notifyOwnersOpportunityDeleted(Trigger.old);
    }

    public override void afterUndelete() {
        OpportunityHelper.assignPrimaryContact(newOppMap);
    }
}