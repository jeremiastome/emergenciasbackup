public class LegacySystemServiceList extends WSEmergenciasResponse {
    @AuraEnabled public LegacySystemService[] EmerphoneServiceList {get; set;}
    @AuraEnabled public LegacySystemService[] GTEServiceList {get; set;}
    @AuraEnabled public LegacySystemService[] RCDServiceList {get; set;}
    @AuraEnabled public String mensaje {get; set;}

    public LegacySystemServiceList() {}
}