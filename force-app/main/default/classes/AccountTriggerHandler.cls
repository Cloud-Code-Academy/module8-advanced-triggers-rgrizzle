public with sharing class AccountTriggerHandler extends TriggerHandler{
    public AccountTriggerHandler() {
    }

    public override void beforeInsert() {
        AccountHelper.setRating(Trigger.new);
        AccountHelper.addressCopy(Trigger.new);
        AccountHelper.setTypeProspect(Trigger.new);
    }

    public override void afterInsert() {
        AccountHelper.defaultContact(Trigger.new);
    }
}