public class UploadBeneficiariosController {
	@AuraEnabled
    public static List<CoberturaWrapper> getProducts(String titularId) {
        Titular__c titular = [SELECT id, Contrato__c FROM Titular__c WHERE id = :titularId LIMIT 1];
		List<Cobertura__c> products =
            [SELECT id,
             Nombre_de_Producto__c
             FROM Cobertura__c
             WHERE Contrato__c = :titular.Contrato__c
            ];
		List<CoberturaWrapper> result = new List<CoberturaWrapper>();
		for(Cobertura__c product : products) {
			result.add(new CoberturaWrapper(product));
		}
        return result;
    }

	@AuraEnabled
    public static ResponseUpload uploadFile(String fileName, List<String> bodyLines,
		String contentType, String titularId, List<String> productIds,
		String recordTypeName, Integer offset, String documentId) {
		Id contractId = [SELECT id, Contrato__c FROM Titular__c WHERE id = :titularId].Contrato__c;

        RecordType recordType = [SELECT id, DeveloperName FROM RecordType WHERE DeveloperName = :recordTypeName];
        Map<Account, Beneficiario__c> beneficiarioByAccount = new Map<Account, Beneficiario__c>();
        Set<String> cuilSet = new Set<String>();
		Map<Integer, String> cuilByLine = new Map<Integer, String>();
		List<String> results = new List<String>();
        for(Integer i = 0; i < bodyLines.size(); i++) {
			Integer line = 2 + i + Integer.valueOf(offset);
            Map<Account, Beneficiario__c> newBeneficiarioByAccount =
                UploadUtils.buildBeneficiarioWithAccount(bodyLines[i], contractId, recordType, titularId);
			if(newBeneficiarioByAccount != null) {
				Account newAccount;
	            for(Account acc : newBeneficiarioByAccount.keySet()) {
	                newAccount = acc;
	            }
				cuilByLine.put(line, newAccount.CUIL_CUIT__c);
                if(cuilSet.contains(newAccount.CUIL_CUIT__c)) {
                    results.add('Linea '+line+': Id '+newAccount.CUIL_CUIT__c+' duplicado');
                }
                else {
                    beneficiarioByAccount.putAll(newBeneficiarioByAccount);
                }
	            cuilSet.add(newAccount.CUIL_CUIT__c);
			}
            else {
                cuilByLine.put(line, '');
            }
        }

        if(!beneficiarioByAccount.keySet().isEmpty()) {
			String newDocumentId = documentId;
            UploadUtils.UpsertResult resUpsert = UploadUtils.upsertAccounts(beneficiarioByAccount.keySet());
            insertBeneficiarios(beneficiarioByAccount.values(), contractId, cuilSet, resUpsert.upsertSuccess, productIds);
			newDocumentId = UploadUtils.saveResult(resUpsert, cuilByLine, results, titularId, documentId, fileName);
            return UploadUtils.getResponseUpload(resUpsert, newDocumentId);
        }
        return new ResponseUpload(false, 'No se pudieron crear los datos!', '');
    }

	public static void insertBeneficiarios(List<Beneficiario__c> nuevosBeneficiarios,
        Id contractId, Set<String> cuilSet, Set<String> upsertSuccess, List<String> productIds) {
        List<Beneficiario__c> beneficiariosGuardados =
            [SELECT id, CUIL_CUIT__c
            FROM Beneficiario__c
            WHERE Contrato__c = :contractId
            AND CUIL_CUIT__c in :cuilSet
        ];

        Set<String> cuilsGuardados = new Set<String>();
        for(Beneficiario__c beneficiario : beneficiariosGuardados) {
            cuilsGuardados.add(beneficiario.CUIL_CUIT__c);
        }

        List<Beneficiario__c> beneficiariosAGuardar = new List<Beneficiario__c>();
        for(Beneficiario__c beneficiario : nuevosBeneficiarios) {
            Boolean itAlreadyExists = cuilsGuardados.contains(beneficiario.Beneficiario__r.CUIL_CUIT__c);
            Boolean itHasNotFailed = upsertSuccess.contains(beneficiario.Beneficiario__r.CUIL_CUIT__c);
            if(!itAlreadyExists && itHasNotFailed) {
                beneficiariosAGuardar.add(beneficiario);
            }
        }
		
        if(!beneficiariosAGuardar.isEmpty()) {
            insert beneficiariosAGuardar;
			createRecipientCoverage(beneficiariosAGuardar, productIds);
        }
    }

	public static void createRecipientCoverage(List<Beneficiario__c> beneficiarios, List<String> productIds) {
		List<Cobertura_de_Beneficiario__c> recipientCoverages = new List<Cobertura_de_Beneficiario__c>();
		for(Beneficiario__c beneficiario : beneficiarios) {
			for(Id productId : productIds) {
				recipientCoverages.add(new Cobertura_de_Beneficiario__c(
					Beneficiario__c = beneficiario.id,
					Cobertura__c = productId
				));
			}
		}
		if(!recipientCoverages.isEmpty()) {
			insert recipientCoverages;
		}
	}

	public class CoberturaWrapper {
		@AuraEnabled String id {get;set;}
		@AuraEnabled Boolean isSelected {get;set;}
		@AuraEnabled Cobertura__c product {get;set;}

		public CoberturaWrapper(Cobertura__c aProduct) {
			this.id = aProduct.id;
			this.product = aProduct;
			this.isSelected = false;
		}
	}
}