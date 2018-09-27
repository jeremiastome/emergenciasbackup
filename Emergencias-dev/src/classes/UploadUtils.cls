public class UploadUtils {

	public static String saveResult(UploadUtils.UpsertResult resUpsert,
		Map<Integer, String> cuilByLine, List<String> results,
		String contractId, String documentId, String title) {


        Map<String, String[]> upsertFailed = resUpsert.upsertFailed;
        Set<String> cuilsFailed = upsertFailed.keySet();
        for(Integer line : cuilByLine.keySet()) {
            String cuil = cuilByLine.get(line);

            String errors = '';
            if(cuilsFailed.contains(cuil)) {
                for(String error : upsertFailed.get(cuil)) {
                    errors += ' '+error;
                }
                results.add('Linea '+line+': '+errors);
            }
            else if(String.isBlank(cuil)) {
                errors += ' Linea mal armada';
                results.add('Linea '+line+': '+errors);
            }
        }
		if(results.isEmpty()) {
			return documentId;
		}
		String errors = '';
		for(String error : results) {
			errors += error+'\n';
		}

		if(String.isEmpty(documentId)) {
			return createDocument(title, errors, contractId);
		}
		else {
			ContentVersion cv = [
				SELECT id, versiondata, title, ContentDocumentId
				FROM ContentVersion
				WHERE id =: documentId
			];
			ContentDocument cd = [SELECT id FROM ContentDocument WHERE id =:cv.ContentDocumentId LIMIT 1];
			String message = cv.VersionData.toString() + errors;
			System.debug('*** message: ' + message);
			delete cd;
			return createDocument(title, message, contractId);
		}
		return documentId;
    }

	public static String createDocument(String title, String message, String contractId) {
		ContentVersion cv = new Contentversion();
		cv.title = 'fallos-'+title;
		Blob b = Blob.valueOf(message);
		cv.versiondata = b;
		cv.PathOnClient = 'fallos-'+title;
		insert cv;
		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
		cdl.LinkedEntityId = contractId;
		cdl.ShareType = 'V';
		insert cdl;
		return cv.id;
	}

	public static Map<Account, Titular__c> buildTitularWithAccount(String accountString, Id contractId, RecordType recordType) {
		Map<Account, Titular__c> titularByAccount = new Map<Account, Titular__c>();
		Account newAccount = buildAccount(accountString, recordType);
		if(newAccount == null) {
			return null;
		}
		Titular__c newTitular = new Titular__c(Contrato__c = contractId,
			Cliente__r = new Account(CUIL_CUIT__c = newAccount.CUIL_CUIT__c));
		titularByAccount.put(newAccount, newTitular);
		return titularByAccount;
	}

	public static Account buildAccount(String accountString, RecordType recordType) {
		String fieldsString = accountString.replaceAll('"', '');
		String[] fieldsList = fieldsString.split(';');
		if(fieldsList.size() == 5){
			Account newAccount = new Account();
			newAccount.RecordTypeId = recordType.id;
			if(recordType.DeveloperName == 'Business_Account') {
				newAccount.Name = fieldsList[0];
			}
			else {
				newAccount.LastName = fieldsList[0];
			}
			newAccount.Numero_de_Documento__c = fieldsList[1].deleteWhitespace();
			newAccount.Provincia_de_facturacion__c = fieldsList[2];
			newAccount.Phone = fieldsList[3].deleteWhitespace();
			if(String.isBlank(fieldsList[4])) {
				return null;
			}
			newAccount.CUIL_CUIT__c = fieldsList[4].deleteWhitespace();
			return newAccount;
		}
		else {
			return null;
		}
	}

	public static Map<Account, Beneficiario__c> buildBeneficiarioWithAccount(String accountString, Id contractId,
	 	RecordType recordType, Id titularId) {
		String fieldsString = accountString.replaceAll('"', '');
		String[] fieldsList = fieldsString.split(';');
		Map<Account, Beneficiario__c> beneficiarioByAccount = new Map<Account, Beneficiario__c>();
		Account newAccount = buildAccount(accountString, recordType);
		if(newAccount == null) {
			return null;
		}
		Beneficiario__c newBeneficiario = new Beneficiario__c(
			Titular__c = titularId,
			Contrato__c = contractId,
			Beneficiario__r = new Account(CUIL_CUIT__c = newAccount.CUIL_CUIT__c),
			Provincia1__c = fieldsList[2]);
		beneficiarioByAccount.put(newAccount, newBeneficiario);
		return beneficiarioByAccount;
	}

	public static UpsertResult upsertAccounts(Set<Account> accounts) {
		List<Account> accountList = new List<Account>();
		accountList.addAll(accounts);
		Schema.SObjectField externalIDAccount = Account.Fields.CUIL_CUIT__c;
		Database.UpsertResult[] resUpsert = Database.upsert(accountList, externalIDAccount, false);
		Map<String, String[]> upsertFailed = new Map<String, String[]>();
		Set<String> upsertSuccess = new Set<String>();
		for(Integer i = 0; i < resUpsert.size(); i++) {
			if(resUpsert[i].isSuccess()) {
				upsertSuccess.add(accountList[i].CUIL_CUIT__c);
			} else {
				Database.Error[] errors = resUpsert[i].getErrors();
				List<String> errorMessages = new List<String>();
				for(Integer e = 0; e < errors.size(); e++) {
					errorMessages.add(errors[e].getMessage());
				}
				upsertFailed.put(accountList[i].CUIL_CUIT__c, errorMessages);
			}
		}
		UpsertResult upsertResult = new UpsertResult(upsertFailed, upsertSuccess, resUpsert);
		return upsertResult;
	}

	public static ResponseUpload getResponseUpload(UpsertResult upsertResult, String documentId) {
		Boolean isSuccess = true;
		String message = 'El archivo ha sido cargado';
		return new ResponseUpload(isSuccess, message, documentId);
	}

	public class UpsertResult {
		public Map<String, String[]> upsertFailed {get; set;}
		public Set<String> upsertSuccess {get; set;}
		public Database.UpsertResult[] result {get; set;}

		public UpsertResult(Map<String, String[]> upsertFailed, Set<String> upsertSuccess, Database.UpsertResult[] result) {
			this.upsertFailed = upsertFailed;
			this.upsertSuccess = upsertSuccess;
			this.result = result;
		}
	}
}