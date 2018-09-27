public class ClonarContrato  {
	public static Contrato__c clonar(Id conId) {
		return clonar(conId, false);
	}

	public static Contrato__c clonar(Id conId, boolean salesProcess) {
		Map<Id, Contrato__c> result = clonar(new Set<Id> {conId}, salesProcess);
		return result.get(conId);
	}

	public static Map<Id, Contrato__c> clonar(Set<Id> conIds) {
		return clonar(conIds, false);
	}

	public static Map<Id, Contrato__c> clonar(Set<Id> conIds, boolean salesProcess) {
		Map<Id, Contrato__c> contractsByOriginalId = cloneContracts(conIds);

		Map<Id, Titular__c> holdersByOriginalId = cloneHolders(conIds, contractsByOriginalId);
		Map<Id, Beneficiario__c> recipientsByOriginalId = cloneRecipients(conIds, holdersByOriginalId, salesProcess);
		Map<Id, Cobertura__c> coveragesByOriginalId = cloneCoverages(conIds, contractsByOriginalId);
		Map<Id, Cobertura_de_Beneficiario__c> recipientCoveragesByOriginalId = cloneRecipientCoverages(recipientsByOriginalId, coveragesByOriginalId);
		Map<Id, Descuento_Recargo_Aplicado__c> appliedDiscountsByOriginalId = cloneAppliedDiscounts(coveragesByOriginalId);
		cloneAplications(recipientCoveragesByOriginalId, appliedDiscountsByOriginalId);
		cloneAmountDetails(recipientCoveragesByOriginalId);

		return contractsByOriginalId;
	}

	private static Map<Id, Contrato__c> cloneContracts(Set<Id> conIds) {
		List<Contrato__c> contracts = (List<Contrato__c>)Database.query(getCreatableFieldsSOQL('Contrato__c', 'Id IN :conIds'));
		System.debug('Clonando...');
		Map<Id, Contrato__c> contractsByOriginalId = new Map<Id, Contrato__c>();
		for(Contrato__c original : contracts) {
			Contrato__c con = original.clone(false, true);
			if(original.Tarjeta_sin_cifrar__c != null) {
				con.Numero_de_Tarjeta__c = original.Tarjeta_sin_cifrar__c;
			}
			if(original.CBU__c != null) {
				con.CBU_cifrado__c = original.CBU__c;
			}
			con.Sufijo__c = original.Sufijo__c + 1;
			con.Estado__c = 'En proceso de venta';
			con.Numero_Unico_de_Contrato_Con_Sufijo__c = null;
			con.ID_Externo__c=null;			
			contractsByOriginalId.put(original.Id, con);
		}

		insert contractsByOriginalId.values();
		System.debug('Clono!');
		return contractsByOriginalId;
	}

	private static Map<Id, Titular__c> cloneHolders(Set<Id> conIds, Map<Id, Contrato__c> contractsByOriginalId) {
		List<Titular__c> holders = (List<Titular__c>)Database.query(
			getCreatableFieldsSOQL('Titular__c', 'Contrato__c IN :conIds')
		);
		Map<Id, Titular__c> holdersByOriginalId = new Map<Id, Titular__c>();
		for(Titular__c h : holders) {
			Contrato__c con = contractsByOriginalId.get(h.Contrato__c);
			Titular__c clone = h.clone(false, true);
			clone.Contrato__c = con.Id;
			clone.ID_Externo__c = null;
			holdersByOriginalId.put(h.Id, clone);
		}
		insert holdersByOriginalId.values();
		return holdersByOriginalId;
	}

	private static Map<Id, Beneficiario__c> cloneRecipients(Set<Id> conIds, Map<Id, Titular__c> holdersByOriginalId, boolean salesProcess) {
		List<Beneficiario__c> recipients = (List<Beneficiario__c>)Database.query(
			getCreatableFieldsSOQL('Beneficiario__c', 'Contrato__c IN :conIds')
		);

		Map<Id, Beneficiario__c> recipientsByOriginalId = new Map<Id, Beneficiario__c>();
		for(Beneficiario__c r : recipients) {
			Titular__c holder = holdersByOriginalId.get(r.Titular__c);
			Beneficiario__c clone = r.clone(false, true);
			clone.Numero_Club_de_Emergencias__c=null;
			if(salesProcess && clone.Estado__c=='Activo') {
				clone.Estado__c='En Proceso de Venta';
			}
			clone.Titular__c = holder.Id;
			clone.Contrato__c = holder.Contrato__c;

			recipientsByOriginalId.put(r.Id, clone);
		}

		insert recipientsByOriginalId.values();
		return recipientsByOriginalId;
	}

	private static Map<Id, Cobertura__c> cloneCoverages(Set<Id> conIds, Map<Id, Contrato__c> contractsByOriginalId) {
		List<Cobertura__c> coverages = (List<Cobertura__c>)Database.query(
			getCreatableFieldsSOQL('Cobertura__c', 'Contrato__c IN :conIds')
		);
		Map<Id, Cobertura__c> coveragesByOriginalId = new Map<Id, Cobertura__c>();
		for(Cobertura__c c : coverages) {
			Contrato__c con = contractsByOriginalId.get(c.Contrato__c);
			Cobertura__c clone = c.clone(false, true);
			clone.Contrato__c = con.Id;
			clone.Id_Producto_de_Oportunidad__c= null;

			coveragesByOriginalId.put(c.Id, clone);
		}
		insert coveragesByOriginalId.values();
		return coveragesByOriginalId;
	}

	private static Map<Id, Cobertura_de_Beneficiario__c> cloneRecipientCoverages(
		Map<Id, Beneficiario__c> recipientsByOriginalId,
		Map<Id, Cobertura__c> coveragesByOriginalId
	) {
		Set<Id> recipientIds = recipientsByOriginalId.keySet();
		List<Cobertura_de_Beneficiario__c> recipientCoverages = (List<Cobertura_de_Beneficiario__c>)Database.query(
			getCreatableFieldsSOQL('Cobertura_de_Beneficiario__c', 'Beneficiario__c IN :recipientIds')
		);

		Map<Id, Cobertura_de_Beneficiario__c> clones = new Map<Id, Cobertura_de_Beneficiario__c>();
		for(Cobertura_de_Beneficiario__c c : recipientCoverages) {
			Beneficiario__c recipient = recipientsByOriginalId.get(c.Beneficiario__c);
			Cobertura__c coverage = coveragesByOriginalId.get(c.Cobertura__c);
			Cobertura_de_Beneficiario__c clone = c.clone(false, true);
			clone.ID_Externo__c=null;
			clone.Beneficiario__c = recipient.Id;
			clone.Cobertura__c = coverage.Id;
			clones.put(c.Id, clone);
		}
		insert clones.values();

		return clones;
	}

	private static Map<Id, Descuento_Recargo_Aplicado__c> cloneAppliedDiscounts(Map<Id, Cobertura__c> coveragesByOriginalId) {
		Set<Id> coverageIds = coveragesByOriginalId.keySet();
		List<Descuento_Recargo_Aplicado__c> appliedDiscounts = (List<Descuento_Recargo_Aplicado__c>)Database.query(
			getCreatableFieldsSOQL('Descuento_Recargo_Aplicado__c', 'Producto_de_Contrato__c IN :coverageIds')
		);


		Map<Id, Descuento_Recargo_Aplicado__c> clones = new Map<Id, Descuento_Recargo_Aplicado__c>();
		for(Descuento_Recargo_Aplicado__c apd : appliedDiscounts) {
			Cobertura__c coverage = coveragesByOriginalId.get(apd.Producto_de_Contrato__c);
			Descuento_Recargo_Aplicado__c clone = apd.clone(false, true);

			clone.Producto_de_Contrato__c = coverage.Id;
			clone.ID_Externo__c=null;
			clones.put(apd.Id, clone);
		}
		insert clones.values();

		return clones;
	}

	private static void cloneAplications(
		Map<Id, Cobertura_de_Beneficiario__c> recipientCoveragesByOriginalId,
		Map<Id, Descuento_Recargo_Aplicado__c> appliedDiscountsByOriginalId
	) {
		Set<Id> recipientCoverageIds = recipientCoveragesByOriginalId.keySet();
		List<Aplicante__c> aplications = (List<Aplicante__c>)Database.query(
			getCreatableFieldsSOQL('Aplicante__c', 'Cobertura__c IN :recipientCoverageIds')
		);


		List<Aplicante__c> clones = new List<Aplicante__c>();
		for(Aplicante__c app : aplications) {
			Cobertura_de_Beneficiario__c recipientCoverage = recipientCoveragesByOriginalId.get(app.Cobertura__c);
			Descuento_Recargo_Aplicado__c appliedDiscount = appliedDiscountsByOriginalId.get(app.Descuento_Recargo_Aplicado__c);
			Aplicante__c clone = app.clone(false, true);

			clone.Cobertura__c = recipientCoverage.Id;
			clone.Descuento_Recargo_Aplicado__c = appliedDiscount.Id;
			clones.add(clone);
		}
		insert clones;
	}

	private static void cloneAmountDetails(
		Map<Id, Cobertura_de_Beneficiario__c> recipientCoveragesByOriginalId
	) {
		Set<Id> recipientCoverageIds = recipientCoveragesByOriginalId.keySet();
		List<Cantidad_de_producto_de_beneficiaro__c> amountDetails =
			(List<Cantidad_de_producto_de_beneficiaro__c>)Database.query(
				getCreatableFieldsSOQL(
					'Cantidad_de_producto_de_beneficiaro__c',
					'Cobertura_de_Beneficiario__c IN :recipientCoverageIds AND Activo__c = true'
				)
			);

		Map<Id, Cantidad_de_producto_de_beneficiaro__c> clones =
			new Map<Id, Cantidad_de_producto_de_beneficiaro__c>();
		for(Cantidad_de_producto_de_beneficiaro__c amd : amountDetails) {
			Cobertura_de_Beneficiario__c recipientCoverage =
				recipientCoveragesByOriginalId.get(amd.Cobertura_de_Beneficiario__c);
			Cantidad_de_producto_de_beneficiaro__c clone = amd.clone(false, true);

			clone.Cobertura_de_Beneficiario__c = recipientCoverage.Id;

			clones.put(amd.Id, clone);
		}

		insert clones.values();
	}

	// Returns a dynamic SOQL statement for the whole object, includes only creatable
	// fields since we will be inserting a cloned result of this query
	public static string getCreatableFieldsSOQL(String objectName, String whereClause) {
		String selects = '';

		if(whereClause == null || whereClause == '') {
			return null;
		}

		// Get a map of field name and field token
		Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
		list<string> selectFields = new list<string>();

		if (fMap != null) {
			for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
				Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
				if (fd.isCreateable()){ // field is creatable
					selectFields.add(fd.getName());
				}
			}
		}
		if (!selectFields.isEmpty()) {
			for (string s:selectFields) {
				selects += s + ',';
			}
			if (selects.endsWith(',')) {
				selects = selects.substring(0,selects.lastIndexOf(','));
			}
		}
		return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
	}
}