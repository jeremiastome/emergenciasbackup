public class ContractToSAPConverter extends ContractToSAPConverterBase {
	List<CoverageWrapper> coverages;
	Map<String, Interlocutor_Provincia__c> provinceSettings;
	WSGetPositionsFromSAP positionNumbers;
	List<Descuento_Recargo_Aplicado__c> discountRelationsToUpdate;

	public boolean oldPositionNumbersFailed {
		public get;
		private set;
	}

	public ContractToSAPConverter(Id contractId, String operation) {
		super(contractId, operation);

		oldPositionNumbersFailed = false;

		Map<String, CoverageWrapper> coverageWrapperByProduct = new Map<String, CoverageWrapper>();

		List<Cobertura__c> coverageForWrapper = [
			SELECT Id, Cantidad__c, Cantidad_en_transito__c, Adicionales__c, Codigo_de_SAP__c,
				Producto__r.Id, Producto__r.Numero__c, Producto__r.Sector__c
			FROM Cobertura__c
			WHERE Contrato__c = :contractId
		];

		Set<Id> coverageIds = new Set<Id>();
		for(Cobertura__c cov : coverageForWrapper) {
			coverageWrapperByProduct.put(cov.Codigo_de_SAP__c, new CoverageWrapper(cov));
			coverageIds.add(cov.id);
		}

		provinceSettings = Interlocutor_Provincia__c.getall();

		for(Cobertura_de_Beneficiario__c rel : getCoverageRelations(coverageIds)) {
			coverageWrapperByProduct.get(rel.Cobertura__r.Codigo_de_SAP__c).addRecipient(rel);
		}

		discountRelationsToUpdate = new List<Descuento_Recargo_Aplicado__c>();
		for(Descuento_Recargo_Aplicado__c apd : [
			SELECT Id, Fecha_inicio__c, Fecha_Fin__c, Producto_de_Contrato__c,
				Producto_de_Contrato__r.Producto__c, Valor__c, Estado_de_envio__c,
				Descuento_o_Recargo__r.Codigo_de_descuento__c, Producto_de_Contrato__r.Codigo_de_SAP__c,
				Descuento_o_Recargo__r.Valor__c, Descuento_o_Recargo__r.Unidad__c
			FROM Descuento_Recargo_Aplicado__c
			WHERE Producto_de_Contrato__c IN :coverageIds
				AND Caso__c = null
				AND Estado_de_envio__c != 'Enviado baja'
		]) {
			coverageWrapperByProduct.get(apd.Producto_de_Contrato__r.Codigo_de_SAP__c).addDiscount(apd);

			if(apd.Estado_de_envio__c == 'Nuevo' || apd.Estado_de_envio__c == 'Baja') {
				discountRelationsToUpdate.add(apd);
			}
		}

		coverages = coverageWrapperByProduct.values();
		System.debug('Coverages: '+coverages.size());
		positionNumbers = new WSGetPositionsFromSAP();
		if(operation != 'A' && operation != 'S') {
			positionNumbers.getForContract(contract.Numero_Unico_de_Contrato_Con_Sufijo__c);
			System.debug('Result: ' + positionNumbers.result);
			System.debug('Old positions read, success: ' + !positionNumbers.hadError);
			oldPositionNumbersFailed = positionNumbers.hadError;

		}
	}

	public void updateDiscountRelations() {
		update discountRelationsToUpdate;
	}

	//==========================================================================
	//Contract generation

	public override WSSAPContratosPedidos.Pedido_element generateRequest() {
		WSSAPContratosPedidos.Pedido_element result = super.generateRequest();
		result.ListaPosiciones = generatePositions();

		if(result.Cabecera.TipoDocumento == 'VV') {
			WSSAPContratosPedidos.Condiciones_element condPrice = new WSSAPContratosPedidos.Condiciones_element();

			condPrice.TipoOperacion = 'A';
			condPrice.ClaseCondicion = 'ZPR1';
			System.debug(contract);
			condPrice.Importe = ContractToSAPConverterBase.formatNumber(contract.Importe__c, 2);

			condPrice.Unidad = 'C/U';

			condPrice.FechaInicioValidez = result.Cabecera.IniVigenciaContrato;
			condPrice.FechaFinValidez = '29991231';

			if(result.ListaPosiciones.Posicion[0].Condiciones == null) {
				result.ListaPosiciones.Posicion[0].Condiciones = new List<WSSAPContratosPedidos.Condiciones_element>();
			}

			result.ListaPosiciones.Posicion[0].Condiciones.add(condPrice);
		}

		return result;
	}

	private WSSAPContratosPedidos.ListaPosiciones_element generatePositions() {
		WSSAPContratosPedidos.ListaPosiciones_element result = new WSSAPContratosPedidos.ListaPosiciones_element();
		result.posicion = new List<WSSAPContratosPedidos.Posicion_element>();

		for(CoverageWrapper cvw : coverages) {
			result.posicion.addAll(cvw.createPositions());
		}

		for(WSSAPContratosPedidos.Posicion_element pos : result.posicion) {
			integer posNum;

			Interlocutor_Provincia__c provinceSetting = provinceSettings.get(pos.DestinatarioMercancias);
			if(provinceSetting == null || provinceSetting.Codigo_SAP__c == null) {
				pos.DestinatarioMercancias = '';
			}
			else {
				pos.DestinatarioMercancias = provinceSetting.Codigo_SAP__c;
			}

			if(String.isBlank(pos.ZonaDeVentas)) {

				boolean hasMinorDiscount = false;
				if(pos.Condiciones.size() != 0) {
					hasMinorDiscount = pos.Condiciones[0].ClaseCondicion == 'ZDV1';
				}

				posNum = positionNumbers.getPosNumber(
					pos.CodigoMaterial,
					pos.CondIVABenef,
					pos.DestinatarioMercancias,
					hasMinorDiscount
				);
			}
			else {
				posNum = positionNumbers.getPosNumber(pos.CodigoMaterial, pos.ZonaDeVentas);
			}

			if(posNum == -1) {
				if(operation == 'S') {
					pos.TipoOperacion = 'S';
				}
				else {
					pos.TipoOperacion = 'A';
				}
				posNum = positionNumbers.getNextNumber();
				List<WSSAPContratosPedidos.Condiciones_element> conditions = new List<WSSAPContratosPedidos.Condiciones_element>();
				for(WSSAPContratosPedidos.Condiciones_element condition : pos.Condiciones) {
					if(operation == 'S' && condition.TipoOperacion != 'B') {
						condition.TipoOperacion = 'S';
						conditions.add(condition);
					}
					else if(condition.TipoOperacion == 'M') {
						//Conditions that were already sent should still count as an addition for
						// new positions.
						//Clone the condition so this modification does not apply to other positions
						// with the same condition.
						WSSAPContratosPedidos.Condiciones_element clone = condition.clone();
						clone.TipoOperacion = 'A';
						conditions.add(clone);
					}
					else if(condition.TipoOperacion == 'A') {
						conditions.add(condition);
					}
				}
				pos.Condiciones = conditions;
			}
			else {
				pos.TipoOperacion = operation;
			}
			pos.NumeroPosicion = String.valueOf(posNum);
		}

		result.posicion.addAll(positionNumbers.generateDeletePositions());

		return result;
	}

	//==========================================================================

	private List<Cobertura_de_Beneficiario__c> getCoverageRelations(Set<Id> coverageIds) {
		//Si la operacion NO es baja filtro por beneficiarios no dados de baja,
		//si la operacion es baja mando todos (sin filtro)
		List<Cobertura_de_Beneficiario__c> rels;
		if(operation != 'B' && operation != 'S') {
			rels = [
				SELECT Id, Tratamiento_de_IVA__c, Cantidad_de_Padron__c, Cantidad_domicilio__c,
					Cantidad_domicilio_en_transito__c, Cobertura__c,
					Cobertura__r.Producto__c, Cobertura__r.Codigo_de_SAP__c,
					Beneficiario__r.RecordType.DeveloperName, Beneficiario__r.Rubro_del_domicilio__c,
					Beneficiario__r.Provincia1__c, Beneficiario__r.Fecha_de_padron__c,
					Beneficiario__r.Tratamiento_IVA__c, Beneficiario__r.N_mero_nico_de_Beneficiario__c, (
						SELECT Id, Fin_Vigencia__c, Inicio_Vigencia__c, Descuento_Recargo_Aplicado__r.Codigo_de_descuento__c
						FROM Aplicantes__r
						WHERE Caso__c = null
					)
				FROM Cobertura_de_Beneficiario__c
				WHERE Cobertura__c IN :coverageIds
					AND Beneficiario__r.Estado__c = 'Activo'
					AND Beneficiario__r.Tipo_de_Imputacion__c != '03'
					AND Caso__c = null
					AND Beneficiario__r.Caso__c = null
			];
		}
		else {
			rels = [
				SELECT Id, Tratamiento_de_IVA__c, Cantidad_de_Padron__c, Cantidad_domicilio__c,
					Cantidad_domicilio_en_transito__c, Cobertura__c,
					Cobertura__r.Producto__c, Cobertura__r.Codigo_de_SAP__c,
					Beneficiario__r.RecordType.DeveloperName, Beneficiario__r.Rubro_del_domicilio__c,
					Beneficiario__r.Provincia1__c, Beneficiario__r.Fecha_de_padron__c,
					Beneficiario__r.Tratamiento_IVA__c, Beneficiario__r.N_mero_nico_de_Beneficiario__c, (
						SELECT Id, Fin_Vigencia__c, Inicio_Vigencia__c, Descuento_Recargo_Aplicado__r.Codigo_de_descuento__c
						FROM Aplicantes__r
						WHERE Caso__c = null
					)
				FROM Cobertura_de_Beneficiario__c
				WHERE Cobertura__c IN :coverageIds
					AND Beneficiario__r.Estado__c != 'Baja'
					AND Beneficiario__r.Tipo_de_Imputacion__c != '03'
					AND Caso__c = null
					AND Beneficiario__r.Caso__c = null
			];
		}

		return rels;
	}

	//==========================================================================
	//Helper classes
	public class CoverageWrapper {
		Product2 product;
		Cobertura__c coverage;
		Map<String, List<Cobertura_de_Beneficiario__c>> unitRecipients;
		List<Cobertura_de_Beneficiario__c> fullDiscountRecipients;
		List<Cobertura_de_Beneficiario__c> addressRecipients;
		List<Cobertura_de_Beneficiario__c> massiveRecipients;
		List<Descuento_Recargo_Aplicado__c> discountsRelations;
		Descuento_Recargo_Aplicado__c freeMinorDiscount;

		public CoverageWrapper(Cobertura__c cov) {
			coverage = cov;
			product = cov.Producto__r;
			unitRecipients = new Map<String, List<Cobertura_de_Beneficiario__c>>();
			fullDiscountRecipients = new List<Cobertura_de_Beneficiario__c>();
			massiveRecipients = new List<Cobertura_de_Beneficiario__c>();
			addressRecipients = new List<Cobertura_de_Beneficiario__c>();
			discountsRelations = new List<Descuento_Recargo_Aplicado__c>();
		}

		public List<WSSAPContratosPedidos.Posicion_element> createPositions() {
			List<WSSAPContratosPedidos.Condiciones_element> conditions = createConditions();
			List<WSSAPContratosPedidos.Posicion_element> result = createUnitPositions(conditions);
			result.addAll(createAddressPositions(conditions));
			result.addAll(createMassivePositions(conditions));
			return result;
		}

		public void addRecipient(Cobertura_de_Beneficiario__c relation) {
			String rtDevName = relation.Beneficiario__r.RecordType.DeveloperName;
			if(rtDevName == 'Domicilio') {
				addressRecipients.add(relation);
			}
			else if(rtDevName == 'Padron') {
				massiveRecipients.add(relation);
			}
			else {
				//Auto or Persona
				boolean hasMinorDiscount = false;
				if(relation.Aplicantes__r != null) {
					for(Aplicante__c apli : relation.Aplicantes__r) {
						if(apli.Descuento_Recargo_Aplicado__r.Codigo_de_descuento__c == 'ZDV1') {
							hasMinorDiscount = true;
							break;
						}
					}
				}
				if(hasMinorDiscount) {
					fullDiscountRecipients.add(relation);
				}
				else {
					String key = relation.Beneficiario__r.Tratamiento_IVA__c
						+ relation.Beneficiario__r.Provincia1__c;
					if(!unitRecipients.containsKey(key)) {
						unitRecipients.put(key, new List<Cobertura_de_Beneficiario__c>());
					}
					unitRecipients.get(key).add(relation);
				}
			}
		}

		public void addDiscount(Descuento_Recargo_Aplicado__c relation) {
			if(relation.Descuento_o_Recargo__r.Codigo_de_descuento__c == 'ZDV1') {
				freeMinorDiscount = relation;
			}
			else {
				discountsRelations.add(relation);
			}
		}

		private List<WSSAPContratosPedidos.Posicion_element> createUnitPositions(List<WSSAPContratosPedidos.Condiciones_element> conditions) {
			List<WSSAPContratosPedidos.Posicion_element> result = new List<WSSAPContratosPedidos.Posicion_element>();

			for(List<Cobertura_de_Beneficiario__c> recipients : unitRecipients.values()) {
				WSSAPContratosPedidos.Posicion_element pos = createUnitPosition(recipients);
				pos.Condiciones.addAll(conditions);
				result.add(pos);
			}
			for(Cobertura_de_Beneficiario__c recipient : fullDiscountRecipients) {
				WSSAPContratosPedidos.Posicion_element pos = createUnitPosition(new List<Cobertura_de_Beneficiario__c> {recipient});
				WSSAPContratosPedidos.Condiciones_element condition = createCondition(freeMinorDiscount);

				Aplicante__c aplicant;

				for(Aplicante__c apl : recipient.Aplicantes__r) {
					if(apl.Descuento_Recargo_Aplicado__r.Codigo_de_descuento__c == 'ZDV1') {
						aplicant = apl;
						break;
					}
				}

				condition.FechaInicioValidez =
					ContractToSAPConverterBase.formatDate(aplicant.Inicio_Vigencia__c);
				condition.FechaFinValidez =
					ContractToSAPConverterBase.formatDate(aplicant.Fin_Vigencia__c);
				pos.Condiciones.add(condition);//Make sure the free minor discount is always the first
				pos.Condiciones.addAll(conditions);
				result.add(pos);
			}

			return result;
		}

		private WSSAPContratosPedidos.Posicion_element createUnitPosition(List<Cobertura_de_Beneficiario__c> recipients) {
			WSSAPContratosPedidos.Posicion_element pos = new WSSAPContratosPedidos.Posicion_element();

			pos.CodigoMaterial = product.Numero__c;
			pos.Cantidad = ContractToSAPConverterBase.formatNumber(recipients.size(), 3);
			pos.Sector = product.Sector__c;
			pos.ZonaDeVentas = '';
			pos.CondIVABenef = recipients[0].Beneficiario__r.Tratamiento_IVA__c;
			System.debug('Recipients: '+recipients[0].Beneficiario__r.id);
			pos.DestinatarioMercancias = recipients[0].Beneficiario__r.Provincia1__c;
			pos.GrupoDeClientes = '';
			pos.MotivoDeRechazo = '';
			pos.Cobrador = '';
			pos.Radio = '';

			pos.Condiciones = new List<WSSAPContratosPedidos.Condiciones_element>();

			return pos;
		}

		private List<WSSAPContratosPedidos.Posicion_element> createAddressPositions(List<WSSAPContratosPedidos.Condiciones_element> conditions) {
			List<WSSAPContratosPedidos.Posicion_element> result = new List<WSSAPContratosPedidos.Posicion_element>();
			Producto_Transito__c separationSetting = Producto_Transito__c.getValues(product.Numero__c);
			if(separationSetting != null) {
				for(Cobertura_de_Beneficiario__c relation : addressRecipients) {
					if(relation.Cantidad_domicilio__c != null
						&& relation.Cantidad_domicilio__c > 0
					) {
						WSSAPContratosPedidos.Posicion_element pos = createAddressPosition(
							relation,
							conditions,
							product.Numero__c,
							relation.Cantidad_domicilio__c
						);
						result.add(pos);
					}

					if(relation.Cantidad_domicilio_en_transito__c != null
						&& relation.Cantidad_domicilio_en_transito__c > 0
					) {
						WSSAPContratosPedidos.Posicion_element pos = createAddressPosition(
							relation,
							conditions,
							product.Numero__c + ' TRA',
							relation.Cantidad_domicilio_en_transito__c
						);
						result.add(pos);
					}
				}
			}
			else {
				for(Cobertura_de_Beneficiario__c relation : addressRecipients) {
					decimal amount = 0;
					if(relation.Cantidad_domicilio__c != null
						&& relation.Cantidad_domicilio__c > 0
					) {
						amount += relation.Cantidad_domicilio__c;
					}

					if(relation.Cantidad_domicilio_en_transito__c != null
						&& relation.Cantidad_domicilio_en_transito__c > 0
					) {
						amount += relation.Cantidad_domicilio_en_transito__c;
					}
					result.add(
						createAddressPosition(
							relation,
							conditions,
							product.Numero__c,
							amount
						)
					);
				}
			}
			return result;
		}

		private WSSAPContratosPedidos.Posicion_element createAddressPosition(
			Cobertura_de_Beneficiario__c relation,
			List<WSSAPContratosPedidos.Condiciones_element> conditions,
			String prodName,
			decimal amount
		) {
			WSSAPContratosPedidos.Posicion_element pos = new WSSAPContratosPedidos.Posicion_element();
			pos.CodigoMaterial = prodName;
			pos.Cantidad = ContractToSAPConverterBase.formatNumber(amount, 3);

			pos.Sector = product.Sector__c;
			pos.ZonaDeVentas = relation.Beneficiario__r.N_mero_nico_de_Beneficiario__c.right(3);
			pos.CondIVABenef = relation.Beneficiario__r.Tratamiento_IVA__c;
			System.debug('Recipients: '+relation.Beneficiario__r.id);
			pos.DestinatarioMercancias = relation.Beneficiario__r.Provincia1__c;
			pos.GrupoDeClientes = relation.Beneficiario__r.Rubro_del_domicilio__c;
			pos.MotivoDeRechazo = '';
			pos.Cobrador = '';
			pos.Radio = '';
			pos.Condiciones = new List<WSSAPContratosPedidos.Condiciones_element>();
			pos.Condiciones.addAll(conditions);

			return pos;
		}

		private List<WSSAPContratosPedidos.Posicion_element> createMassivePositions(List<WSSAPContratosPedidos.Condiciones_element> conditions) {
			List<WSSAPContratosPedidos.Posicion_element> result = new List<WSSAPContratosPedidos.Posicion_element>();

			for(Cobertura_de_Beneficiario__c relation : massiveRecipients) {
				WSSAPContratosPedidos.Posicion_element pos = new WSSAPContratosPedidos.Posicion_element();

				pos.CodigoMaterial = product.Numero__c;
				pos.Cantidad = ContractToSAPConverterBase.formatNumber(relation.Cantidad_de_Padron__c, 3);
				pos.Sector = product.Sector__c;
				pos.ZonaDeVentas = '';
				pos.CondIVABenef = relation.Tratamiento_de_IVA__c;
				System.debug('Recipients: '+relation.id);
				pos.DestinatarioMercancias = relation.Beneficiario__r.Provincia1__c;
				pos.GrupoDeClientes = '';
				pos.MotivoDeRechazo = '';
				pos.Cobrador = '';
				pos.Radio = '';

				pos.Condiciones = new List<WSSAPContratosPedidos.Condiciones_element>();
				pos.Condiciones.addAll(conditions);

				result.add(pos);
			}

			return result;
		}

		private List<WSSAPContratosPedidos.Condiciones_element> createConditions() {
			List<WSSAPContratosPedidos.Condiciones_element> result = new List<WSSAPContratosPedidos.Condiciones_element>();

			for(Descuento_Recargo_Aplicado__c rel : discountsRelations) {
				result.add(createCondition(rel));
			}

			return result;
		}

		private WSSAPContratosPedidos.Condiciones_element createCondition(Descuento_Recargo_Aplicado__c relation) {
			WSSAPContratosPedidos.Condiciones_element result = new WSSAPContratosPedidos.Condiciones_element();

			result.ClaseCondicion = relation.Descuento_o_Recargo__r.Codigo_de_descuento__c;

			if(relation.Valor__c != null) {
				System.debug('Descuento recargo aplicado: ' +relation);
				result.Importe = ContractToSAPConverterBase.formatNumber(relation.Valor__c, 2);
			}
			else {
				result.Importe = ContractToSAPConverterBase.formatNumber(relation.Descuento_o_Recargo__r.Valor__c, 2);
			}

			if(relation.Estado_de_envio__c == 'Enviado') {
				result.TipoOperacion = 'M';
			}
			else if(relation.Estado_de_envio__c == 'Baja') {
				result.TipoOperacion = 'B';
				relation.Estado_de_envio__c = 'Enviado baja';
			}
			else {//relation.Estado_de_envio__c == 'Nuevo'
				result.TipoOperacion = 'A';
				relation.Estado_de_envio__c = 'Enviado';
			}

			result.Unidad = relation.Descuento_o_Recargo__r.Unidad__c;
			result.FechaInicioValidez =
				ContractToSAPConverterBase.formatDate(relation.Fecha_inicio__c);
			result.FechaFinValidez = ContractToSAPConverterBase.formatDate(relation.Fecha_Fin__c);

			return result;
		}
	}
}