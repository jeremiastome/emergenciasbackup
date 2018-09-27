public class Oportunidad_enviarAprobacionController {
	@AuraEnabled
	public static String sendForApproval(Id oppId) {
		Boolean esContratoDePadrones = [
			SELECT Id,
			Contrato__r.Contrato_de_Padrones__c
			FROM Opportunity
			WHERE Id = :oppId
		].Contrato__r.Contrato_de_Padrones__c;

		Opportunity opp;
		if(esContratoDePadrones) {
			opp = getDataOpportunityWithPadron(oppId);
		}
		else {
			opp = getDataOpportunity(oppId);
		}
		if (String.isBlank(opp.Contrato__c)) {
			return Label.Error_enviando_oportunidad_a_aprobacion;
		}
		if (opp.isClosed) {
			return Label.La_oportunidad_ya_se_encuentra_cerrada;
		}
		List<Contrato__c> contracts = new List<Contrato__c> ([
		                                                     SELECT Forma_de_pago__c, Condicion_de_pago__c, Oficina_de_Venta__c,
															(SELECT Id FROM Beneficiarios__r)
		                                                     FROM Contrato__c
		                                                     WHERE Id = :opp.Contrato__c
		                                                     ]);

		List<Cobertura__c> contractProducts = new List<Cobertura__c> ([
		                                                              SELECT Id, Cantidad_de_capitas__c
		                                                              FROM Cobertura__c
		                                                              WHERE Contrato__c = :opp.Contrato__c
		                                                              ]);


		List<Beneficiario__c> contractsRecipients = new List<Beneficiario__c> ([
		                                                                       SELECT id, Cantidad_Coberturas__c
		                                                                       FROM Beneficiario__c
		                                                                       WHERE Contrato__c = :opp.Contrato__c
		                                                                       ]);

		String[] todosErrores = new String[] { };

        if (opp.Coberturas_de_Beneficiarios_creadas__r.size()==0 &&
            !contractsRecipients.isEmpty() &&
            !contractProducts.isEmpty()) {

            return Label.No_se_han_registrado_coberturas;
        }

		//Validar cobertura de beneficiario
		String[] errorCoberturaBeneficiario = new String[] { };
		String[] errorCoberturaProducto = new String[] { };

		if (!contractsRecipients.isEmpty() && !contractProducts.isEmpty()) {
			for (Beneficiario__c recipient : contractsRecipients) {

				if (recipient.Cantidad_Coberturas__c == 0) {
					errorCoberturaBeneficiario.add('Beneficiario');
					break;
				}
			}
			for (Cobertura__c product : contractProducts) {
				if (product.Cantidad_de_capitas__c == 0) {
					errorCoberturaProducto.add('Producto de Contrato');
					break;
				}
			}

			if (!errorCoberturaBeneficiario.isEmpty()) {
				todosErrores.add(Label.EnviarAprobacionSinBeneficiarioAsociado);

			}

			if (!errorCoberturaProducto.isEmpty()) {
				todosErrores.add(Label.EnviarAprobacionFaltaProductos);

			}
		}



		// Validar cuenta asociada
		String[] erroresCuenta = new String[] { };

		if (String.isBlank(opp.Account.BillingCity) || String.isBlank(opp.Account.BillingCountry)
		    || String.isBlank(opp.Account.BillingState) || String.isBlank(opp.Account.BillingStreet)
		) {
			erroresCuenta.add('Dirección');
		}

		if (String.isBlank(opp.Account.Condicion_IVA__c)) {
			erroresCuenta.add('Condición de IVA');
		}

		if (String.isBlank(opp.Account.Sociedad__c)) {
			//return 'El campo Sociedad del cliente esta vacío, dé aviso a su supervisor para contactar al administrador del sistema';
		}

		if (opp.Requiere_dispositivo__c && String.isBlank(opp.Account.BillingPostalCode)) {
			erroresCuenta.add('Código Postal');
		}

        if (String.isBlank(opp.Account.BillingCountry)) {
			erroresCuenta.add('Pais de domicilio');
		}

		// Si es person account
		if (opp.Account.RecordType.DeveloperName == 'PersonAccount') {
			if (String.isBlank(opp.Account.Tipo_de_documento__c)) {
				erroresCuenta.add('Tipo de documento');
			}

			if (String.isBlank(opp.Account.Numero_de_documento__c)) {
				erroresCuenta.add('Numero de documento');
			}
		}

		if (!erroresCuenta.isEmpty()) {
			todosErrores.add(
			                 String.format(Label.EnviarAprobacionFaltanCampos, new String[] { 'la cuenta', String.join(erroresCuenta, '<br/> ') })
			);
		}

		// Validar oportunidad
		String[] erroresOpp = new String[] { };

		if (opp.Venta_sin_contrato__c) {

			if (opp.Amount == null) {
				erroresOpp.add('Importe');
			}
		}
		If (opp.contrato__r.Productos_con_dispositvo__c > 0 && opp.forma_de_entrega__c == null) {
			erroresOpp.add('Forma de entrega');
		}

		if (String.isBlank(opp.Grupo_de_Vendedores__c)) {
			return 'Falta Grupo de vendedor en la oportunidad, dé aviso a su supervisor para contactarse con el administrador.';
		}

        if (String.isBlank(opp.Organizacion_de_Ventas__c)) {
			return 'Falta Organización de Venta en el contrato u oportunidad, dé aviso a su supervisor para contactarse con el administrador.';
		}

        if (String.isBlank(opp.Numero_unico_De_Contrato__c)) {
			return 'Falta Número único de contrato, dé aviso a su supervisor para contactarse con el administrador.';
		}

        if (String.isBlank(opp.Oficina_de_Venta__c)) {
			return 'Falta Oficina de venta en la oportunidad, dé aviso a su supervisor para contactarse con el administrador.';
		}

        if (String.isBlank(opp.Canal_de_Distribucion__c)) {
			return 'Falta Canal de Distribución en la oportunidad, dé aviso a su supervisor para contactarse con el administrador.';
		}

		if (String.isBlank(opp.Vendedor__c)) {
			erroresOpp.add('Vendedor');
		}

		if (!erroresOpp.isEmpty()) {
			todosErrores.add(
			                 String.format(Label.EnviarAprobacionFaltanCampos, new String[] { 'la oportunidad', String.join(erroresOpp, '<br/> ') })
			);
		}

		// Validar contrato
		String[] erroresContrato = new String[] { };
		if (String.isBlank(contracts[0].Forma_de_Pago__c)) {
			erroresContrato.add('Forma de pago');
		}

		if (String.isBlank(contracts[0].Condicion_de_pago__c)) {
			erroresContrato.add('Condicion de pago');
		}

		if (!erroresContrato.isEmpty()) {
			todosErrores.add(
			                 String.format(Label.EnviarAprobacionFaltanCampos, new String[] { 'el contrato', String.join(erroresContrato, '<br/> ') })
			);
			System.debug(todosErrores);
		}

		// Validar productos
		if (contractProducts.size() == 0) {
			todosErrores.add(Label.Aprovacion_no_enviado_falta_agregar_productos);
		}

		// Validar beneficiario
		if (contracts[0].Beneficiarios__r == null || contracts[0].Beneficiarios__r.isEmpty()) {
			todosErrores.add(Label.EnviarAprobacionFaltanBeneficiarios);
		}

		// Validar advertencias
		if (!opp.Advertencias_validadas__c) {
			todosErrores.add(Label.Aprobacion_no_enviado_falta_validar_advertencias);
		}

		if (opp.Advertencias__r.size() != 0 && String.isBlank(opp.Justificacion_para_Advertencias__c)) {
			todosErrores.add(Label.Aprobacion_no_enviado_tiene_advertencias_sin_resolver);
		}

		if (!todosErrores.isEmpty()) {
			return String.join(todosErrores, '<br/>');
		}

		if (Approval.isLocked(oppId)) {
			return Label.Error_la_oportunidad_ya_se_encuentra_esperando_aprobacion;
		}
		else {
			Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
			req.setObjectId(oppId);
			// submit the approval request for processing
			Approval.ProcessResult result = Approval.process(req);

			if (result.isSuccess()) {
				return Label.Oportunidad_enviada_a_aprobacion;
			}
			else {
				return Label.Error_enviando_oportunidad_a_aprobacion;
			}
		}

	}

	public static Opportunity getDataOpportunity(Id oppId) {
		Opportunity opp = [
						   SELECT Id, Amount, Advertencias_validadas__c, Justificacion_para_Advertencias__c,
							Requiere_dispositivo__c, Contrato__c, Contrato__r.Productos_con_dispositvo__c, Venta_sin_contrato__c,
							Grupo_de_Vendedores__c, Vendedor__c, isClosed, Forma_de_Entrega__c, Canal_de_Distribucion__c,
							Organizacion_de_Ventas__c, Numero_unico_De_Contrato__c, Oficina_de_Venta__c,

							(SELECT Id FROM Advertencias__r WHERE Resuelto__c = false),
							(SELECT Id FROM Coberturas_de_Beneficiarios_creadas__r),

						   Account.RecordType.DeveloperName, Account.Tipo_de_documento__c, Account.Numero_de_Documento__c,
						   Account.BillingCity, Account.BillingCountry, Account.BillingState, Account.BillingStreet,
						   Account.Condicion_IVA__c, Account.BillingPostalCode, Account.Sociedad__c
						   FROM Opportunity
						   WHERE Id = :oppId
		];
		return opp;
	}

	public static Opportunity getDataOpportunityWithPadron(Id oppId) {
		Opportunity opp = [
						   SELECT Id, Amount, Advertencias_validadas__c, Justificacion_para_Advertencias__c,
							Requiere_dispositivo__c, Contrato__c, Contrato__r.Productos_con_dispositvo__c, Venta_sin_contrato__c,
							Grupo_de_Vendedores__c, Vendedor__c, isClosed, Forma_de_Entrega__c, Canal_de_Distribucion__c,
							Organizacion_de_Ventas__c, Numero_unico_De_Contrato__c, Oficina_de_Venta__c,

							(SELECT Id FROM Advertencias__r WHERE Resuelto__c = false),
							(SELECT Id, Cantidad_de_Padron__c
							FROM Coberturas_de_Beneficiarios_creadas__r
							WHERE Cantidad_de_Padron__c > 0),

						   Account.RecordType.DeveloperName, Account.Tipo_de_documento__c, Account.Numero_de_Documento__c,
						   Account.BillingCity, Account.BillingCountry, Account.BillingState, Account.BillingStreet,
						   Account.Condicion_IVA__c, Account.BillingPostalCode, Account.Sociedad__c
						   FROM Opportunity
						   WHERE Id = :oppId
		];
		return opp;
	}
}