public class UploadTitularesController {

    @AuraEnabled
    public static ResponseUpload uploadFile(String fileName,
        String[] bodyLines, String contentType, String contractId,
        String recordTypeName, Integer offset, String documentId) {

        RecordType recordType = [SELECT id, DeveloperName FROM RecordType WHERE DeveloperName = :recordTypeName];
        Map<Account, Titular__c> titularByAccount = new Map<Account, Titular__c>();
        Set<String> cuilSet = new Set<String>();
        Map<Integer, String> cuilByLine = new Map<Integer, String>();
        List<String> results = new List<String>();
        for(Integer i = 0; i < bodyLines.size(); i++) {
            Integer line = 2 + i + Integer.valueOf(offset);
            Map<Account, Titular__c> newTitularByAccount =
                UploadUtils.buildTitularWithAccount(bodyLines[i], contractId, recordType);
            Account newAccount;
            if(newTitularByAccount != null) {
                for(Account acc : newTitularByAccount.keySet()) {
                    newAccount = acc;
                }
                cuilByLine.put(line, newAccount.CUIL_CUIT__c);
                if(cuilSet.contains(newAccount.CUIL_CUIT__c)) {
                    results.add('Linea '+line+': Id '+newAccount.CUIL_CUIT__c+' duplicado');
                }
                else {
                    titularByAccount.putAll(newTitularByAccount);
                }
                cuilSet.add(newAccount.CUIL_CUIT__c);
            }
            else {
                cuilByLine.put(line, '');
            }
        }

        if(!titularByAccount.keySet().isEmpty()) {
            String newDocumentId = documentId;
            UploadUtils.UpsertResult resUpsert = UploadUtils.upsertAccounts(titularByAccount.keySet());
            insertTitulares(titularByAccount.values(), contractId, cuilSet, resUpsert.upsertSuccess);
            newDocumentId = UploadUtils.saveResult(resUpsert, cuilByLine, results, contractId, documentId, fileName);
            return UploadUtils.getResponseUpload(resUpsert, newDocumentId);
        }
        return new ResponseUpload(true, 'No se pudieron crear los datos!', documentId);
    }

    public static void insertTitulares(List<Titular__c> nuevosTitulares,
        Id contractId, Set<String> cuilSet, Set<String> upsertSuccess) {
        List<Titular__c> titularesGuardados =
            [SELECT id, CUIT_CUIL__c
            FROM Titular__c
            WHERE Contrato__c = :contractId
            AND CUIT_CUIL__c in :cuilSet
        ];
        Set<String> cuilsGuardados = new Set<String>();
        for(Titular__c titular : titularesGuardados) {
            cuilsGuardados.add(titular.CUIT_CUIL__c);
        }
        List<Titular__c> titularesAGuardar = new List<Titular__c>();
        for(Titular__c titular : nuevosTitulares) {
            Boolean itAlreadyExists = cuilsGuardados.contains(titular.Cliente__r.CUIL_CUIT__c);
            Boolean itHasSuccess = upsertSuccess.contains(titular.Cliente__r.CUIL_CUIT__c);
            if(!itAlreadyExists && itHasSuccess) {
                titularesAGuardar.add(titular);
            }
        }
        if(!titularesAGuardar.isEmpty()) {
            insert titularesAGuardar;
        }
    }
}