public class SendCredential {
	public static Blob generateCredential(Id coberturaBeneficiarioId) {
		PageReference credentialPR = new PageReference('/apex/CredencialBeneficiario');
		credentialPR.getParameters().put('Id', coberturaBeneficiarioId);
		if (!Test.isRunningTest()) {
			return credentialPR.getContentAsPDF();
		}
		return null;
	}

	public static void sendCredentials(List<Cobertura_de_beneficiario__c> coberturasBeneficiario) {
		System.debug('*** Coberturas: ' + coberturasBeneficiario);
		Map<id, List<id>> idCoberturasPorIdContrato = filterByContract(coberturasBeneficiario);
		for(id contrato : idCoberturasPorIdContrato.keySet()) {
			sendEmail(contrato, idCoberturasPorIdContrato.get(contrato));
		}
	}

	public static Boolean canSendProvisoryCredential() {
		Configuracion_para_envio_de_credenciales__c config = [SELECT id, Envia__c
															 FROM Configuracion_para_envio_de_credenciales__c
															 LIMIT 1];
		return config.Envia__c;
	}

	public static Map<id, List<id>> filterByContract(List<Cobertura_de_beneficiario__c> coberturasBeneficiario) {
		Map<id, List<id>> idCoberturasPorIdContrato = new Map<id, List<id>>();
		for(Cobertura_de_beneficiario__c coberturaBeneficiario : coberturasBeneficiario) {
			if(!idCoberturasPorIdContrato.containsKey(coberturaBeneficiario.Beneficiario__r.Contrato__c)) {
				List<id> idsCoberturaBeneficiario = new List<id> {coberturaBeneficiario.id};
				idCoberturasPorIdContrato.put(coberturaBeneficiario.Beneficiario__r.Contrato__c, idsCoberturaBeneficiario);
			}
			else {
				idCoberturasPorIdContrato.get(coberturaBeneficiario.Beneficiario__r.Contrato__c).add(coberturaBeneficiario.id);
			}
		}
		return idCoberturasPorIdContrato;
	}

	@future(callout=true)
	public static void sendEmail(Id contratoId, List<Id> idsCoberturaBeneficiario) {
		Messaging.SingleEmailMessage mail = buildSingleEmailMessage(contratoId);
		List<Cobertura_de_beneficiario__c> coberturasBeneficiario = [SELECT id, Beneficiario__r.Nombre_y_apellido__c
											   FROM Cobertura_de_beneficiario__c
											   WHERE id in :idsCoberturaBeneficiario];

		Messaging.EmailFileAttachment[] attachments = new Messaging.EmailFileAttachment[] {};
		for(Cobertura_de_beneficiario__c cobertura : coberturasBeneficiario) {
			Blob credencial = generateCredential(cobertura.id);
			Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
		    attach.setContentType('text/csv');
		    attach.setFileName(cobertura.Beneficiario__r.Nombre_y_apellido__c+'.pdf');
		    attach.setInline(false);
		    attach.Body = credencial;
			attachments.add(attach);
		}
		mail.setFileAttachments(attachments);
		if (!Test.isRunningTest()) {
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
	}

	public static Messaging.SingleEmailMessage buildSingleEmailMessage(Id contratoId) {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		EmailTemplate et=[Select id from EmailTemplate where name = 'Credencial provisoria v2' limit 1];
		Contrato__c contrato = [SELECT id, Cliente__r.Correo_Electronico__c FROM Contrato__c WHERE id=:contratoId LIMIT 1];
		mail.setTemplateId(et.Id);
		mail.setTargetObjectId(UserInfo.getUserId());
		mail.setTreatTargetObjectAsRecipient(false);
		mail.setToAddresses(New string[]{contrato.Cliente__r.Correo_Electronico__c});
		return mail;
	}
}
