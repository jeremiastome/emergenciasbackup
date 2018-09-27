public class LegacySystemService {
    public String Instante {get; set {
        if (String.isBlank(value)) return;

        InstanteSF = Datetime.newInstance(Long.valueOf(value.removeStart('/Date(').removeEnd('-0300)/')));
    }}
    @AuraEnabled public Datetime InstanteSF {get; set;}
    @AuraEnabled public String NumeroServicio {get; set;}
    @AuraEnabled public String TipoServicio {get; set;}
    @AuraEnabled public String Clasificacion {get; set;}
    @AuraEnabled public String DestinoFinal {get; set;}
    @AuraEnabled public String Diagnostico {get; set;}

    public LegacySystemService() {}
}