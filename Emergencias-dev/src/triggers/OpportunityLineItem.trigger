trigger OpportunityLineItem on OpportunityLineItem (after insert, after update, after delete) {
	if(Trigger.isDelete) {
		OpportunityLineItemTriggerHelper.deleteCoverage(Trigger.oldMap.keySet());
	}
	else {
		OpportunityLineItemTriggerHelper.upsertCoverageObjects(Trigger.new);
	}
}