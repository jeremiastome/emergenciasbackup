public class Opp_ValidarAdvertenciasController {
	@AuraEnabled
	public static List<Advertencia__c> validateWarnings(Id oppId) {
		Opportunity opp = getOpportunityData(oppId);

		Map<String, Advertencia__c> result = new Map<String, Advertencia__c>();
		for(Advertencia__c warning : opp.Advertencias__r) {
			result.put(warning.Clase_de_advertencia__c, warning);
		}

		List<Advertencia__c> warningsToUpsert = new List<Advertencia__c>();
		checkWarning(
			!String.isBlank(opp.Account.Morosidad_SAP__c),
			'Morosidad',
			Label.Advertencia_detalle_morosidad,
			opp,
			warningsToUpsert, //OUT
			result //OUT
		);

		checkWarning(
			opp.Account.Valor_de_rentabilidad__c == 'NR',
			'Rentabilidad',
			Label.Advertencia_detalle_rentabilidad,
			opp,
			warningsToUpsert, //OUT
			result //OUT
		);

		checkWarning(
		    //validar Acceso condicionado de los beneficiarios del contrato asociado
			opp.Account.Zona_de_facturacion__c != null && opp.Account.Zona_de_facturacion__r.Tipo__c == 'Acceso condicionado',
			'Zona de acceso condicionado',
			Label.Advertencia_acceso_condicionado,
			opp,
			warningsToUpsert, //OUT
			result //OUT
		);

		checkWarning(
			checkOpportunityForPAUAccounts(opp),
			'PAU',
			Label.Advertencia_PAU,
			opp,
			warningsToUpsert, //OUT
			result //OUT
		);

		upsert warningsToUpsert;
		opp.Advertencias_validadas__c = true;
		update opp;
		return result.values();
	}

	@AuraEnabled
	public static List<Advertencia__c> getWarnings(Id oppId) {
		return getOpportunityData(oppId).Advertencias__r;
	}

	@AuraEnabled
	public static boolean wasOpportunityValidated(Id oppId) {
		return [
			SELECT Advertencias_validadas__c
			FROM Opportunity
			WHERE Id = :oppId
		].Advertencias_validadas__c;
	}

	private static void checkWarning(
		boolean shouldWarn, String warningType, String detail, Opportunity opp,
		List<Advertencia__c> outUpsertList, Map<String, Advertencia__c> outResultMap
	) {
		if(shouldWarn) {
			if(!outResultMap.containsKey(warningType)) {
				Advertencia__c adv = new Advertencia__c(
					Clase_de_advertencia__c = warningType,
					Detalle__c = detail,
					Oportunidad__c = opp.Id,
					Resuelto__c = false
				);
				outResultMap.put(warningType, adv);
				outUpsertList.add(adv);
			}
		}
		else {
			Advertencia__c adv = outResultMap.remove(warningType);
			if(adv != null) {
				adv.Resuelto__c = true;
				outUpsertList.add(adv);
			}
		}
	}

	private static Opportunity getOpportunityData(Id oppId) {
		return [
			SELECT Id, Advertencias_validadas__c, Contrato__c, Account.Morosidad_SAP__c,
				Account.Valor_de_rentabilidad__c, Account.Es_PAU__c, Account.Zona_de_facturacion__c,
				Account.Zona_de_facturacion__r.Tipo__c, (
					SELECT Id, Clase_de_advertencia__c, Detalle__c, Oportunidad__c, Resuelto__c
					FROM Advertencias__r
					WHERE Resuelto__c = false
				)
			FROM Opportunity
			WHERE Id = :oppId
		];
	}

	private static boolean checkOpportunityForPAUAccounts(Opportunity opp) {
		if(opp.Account.Es_PAU__c) {
			return true;
		}

		for(Beneficiario__c recipient : [
			SELECT Beneficiario__r.Es_PAU__c
			FROM Beneficiario__c
			WHERE Contrato__c = :opp.Contrato__c
		]) {
			if(recipient.Beneficiario__r.Es_PAU__c) {
				return true;
			}
		}
		return false;
	}

	public static void getBeneficiarios(Id oppId) {
		Opportunity opp = [select id, Contrato__c from Opportunity WHERE id = :oppId];
		Id contractId = opp.Contrato__c;
		List<Beneficiario__c> beneficiarios =
			[SELECT id, Cliente__c, Cliente__r.BillingLatitude,
			Cliente__r.BillingLongitude,
			Cliente__r.BillingStreet, Cliente__r.BillingCity,
			Cliente__r.BillingCountry,
			Cliente__r.Zona_de_Acceso_Condicionado__c,
			Cliente__r.Zona_de_facturacion__c
			FROM Beneficiario__c
			WHERE Contrato__c = :contractId
			AND (NOT Cliente__c = null)
		];

		Map<id, Account> clientesPorIdDeBeneficiario = new Map<Id, Account>();
		Map<id, Account> clientesAActualizarPorIdDeBeneficiario = new Map<Id, Account>();

		List<Id> idsBeneficiarios = new List<Id>();
		for(Beneficiario__c beneficiario : beneficiarios) {
			idsBeneficiarios.add(beneficiario.id);
			Account clienteAsociado = beneficiario.Cliente__r;
			if(clienteAsociado.Zona_de_facturacion__c == null) {
				clientesAActualizarPorIdDeBeneficiario.put(beneficiario.id, clienteAsociado);
			}
		}

		List<Cobertura_de_beneficiario__c> coberturas =
			[SELECT id,
			Beneficiario__c,
			Creado_en_Oportunidad__c,
			Cobertura__c,
			Cobertura__r.Producto__r.Valida_zona_de_acceso_condicionado__c
			FROM Cobertura_de_beneficiario__c
			WHERE Beneficiario__c in :idsBeneficiarios
			AND Cobertura__r.Contrato__c = :contractId
		];
	}
}