public with sharing class SelectRecordTypeController {
    
    @AuraEnabled
    public static PicklistOption[] getRecordOptions() {
		PicklistOption[] picklist = new PicklistOption[]{};
        picklist.add(new PicklistOption('Persona', 'PersonAccount'));
        picklist.add(new PicklistOption('Empresa', 'Business_Account'));
      
        return picklist;
    }
    
    public class PicklistOption {
        @AuraEnabled public String text {get; set;}
        @AuraEnabled public String value {get; set;}
        
        public PicklistOption(String text, String value) {
            this.text = text;
            this.value = value;
        }
    }
}