public class AgregarProductosController {
	public String ProductToAdd {get; set;}
	public List<ProductToAddWrapper> Products {get; set;}
	public integer ProductToRemove {get; set;}
	public Id OpportunityId {get; set;}
	public Id ContractId {get; set;}
	public List<SelectOption> DiscountTypes {get; set;}
	public Set<String> AvailableProductsNames {get; set;}
	public boolean AllowOnlyDiscounts {get; set;}
	public Id ReturnRecord {get; set;}
	public List<SelectOption> ivaTreatments {get; set;}
	public Map<String, String> ivaTreatmentMap {get; set;}
	public List<SelectOption> provinceOptions {get; set;}
	public Map<String, String> provinceMap {get; set;}
	public SimulationResult simulation {get; set;}

	private Map<String, Product2> productsByName;
	private List<Cobertura__c> coveragesToDelete = new List<Cobertura__c>();
	private integer lastWrapperIndex = 0;
	private String userSalespersonGroup;
	private String accountType;
	private boolean isPostSale;
	private Id additionCaseId;

	public AgregarProductosController() {
		AllowOnlyDiscounts = String.IsNotBlank(ApexPages.currentPage().getParameters().get('onlyDisc'));
		ReturnRecord = ApexPages.currentPage().getParameters().get('retId');
		products = new List<ProductToAddWrapper>();
		ProductToAdd = '';

		DiscountTypes = new List<SelectOption> {
			new SelectOption('Ninguno', 'Ninguno'),
			new SelectOption('Pre-aprobado', 'Pre-aprobado'),
			new SelectOption('Personalizado', 'Personalizado')
		};

		getContractId();

		Contrato__c contract = [
			SELECT Id, Canal_de_Distribucion__c, Vendedor__r.Organizacion_de_Venta__c, Vendedor__r.Grupo_de_Vendedores__c,
				Cliente__r.RecordType.DeveloperName
			FROM Contrato__c
			WHERE Id = :ContractId
		];

		if(contract.Cliente__r.RecordType.DeveloperName == 'PersonAccount') {
			accountType = 'Personal';
		}
		else {
			accountType = 'Empresa';
		}
		userSalespersonGroup = contract.Vendedor__r.Grupo_de_Vendedores__c;
		isPostSale = ReturnRecord.getSObjectType() != Schema.Opportunity.SObjectType;

		getAvailableProducts(contract.Canal_de_Distribucion__c);
		prepareSelectOptions();
	}

	public PageReference save() {
		List<Cobertura__c> coverages = new List<Cobertura__c>();
		for(ProductToAddWrapper wrapper : products) {
			coverages.add(wrapper.Coverage);
		}
		upsert coverages;

		if(coveragesToDelete.size() != 0) {
			delete coveragesToDelete;
		}

		List<Descuento_Recargo_Aplicado__c> appliedDiscountsToSave = new List<Descuento_Recargo_Aplicado__c>();
		List<Descuento_Recargo_Aplicado__c> appliedDiscountsToDelete = new List<Descuento_Recargo_Aplicado__c>();
		for(ProductToAddWrapper wrapper : products) {
			if(!wrapper.discountsAreValid()) {
				return null;
			}
			appliedDiscountsToSave.addAll(wrapper.getDiscountsToSave(additionCaseId));
			appliedDiscountsToDelete.addAll(wrapper.getDiscountsToDelete());
		}
		if(appliedDiscountsToSave.size() != 0) {
			upsert appliedDiscountsToSave;
		}

		if(appliedDiscountsToDelete.size() != 0) {
			delete appliedDiscountsToDelete;
		}

		return new PageReference('/' + ReturnRecord);
	}

	public void getProductToAddDetails() {
		if(AvailableProductsNames.contains(ProductToAdd)) {
			ProductToAddWrapper olw = new ProductToAddWrapper(
				ContractId,
				productsByName.get(ProductToAdd),
				userSalespersonGroup,
				accountType,
				isPostSale,
				additionCaseId,
				lastWrapperIndex++,
				ReturnRecord
			);

			AvailableProductsNames.remove(ProductToAdd);
			products.add(olw);
			ProductToAdd = '';
		}
	}

	public void removeProduct() {
		integer productIndex = -1;
		for(Integer i = 0; i < Products.size(); i++) {
			if(Products[i].Index == ProductToRemove) {
				productIndex = i;
				AvailableProductsNames.add(Products[i].MainProduct.Numero__c);
				break;
			}
		}

		if(productIndex >= 0) {
			if(Products[productIndex].Coverage.Id != null) {
				coveragesToDelete.add(Products[productIndex].Coverage);
			}
			Products.remove(productIndex);
		}
	}

	public void regenerateOpportunityLineItems() {
		List<Cobertura__c> coverages = [
			SELECT Id, Adicionales__c, Descuento__c, Cantidad__c, Cantidad_de_menores__c,
				Producto__c, Producto__r.Numero__c, Producto__r.Sector__c, (
					SELECT Id, Fecha_Fin__c, Fecha_inicio__c, Codigo_de_descuento__c,
						Cantidad_de_Bonificados__c, Caso__c, Valor__c, Nombre_de_descuento__c,
						Descuento_o_Recargo__c
					FROM Descuentos_Recargos_Aplicados__r
					WHERE Caso__c = :additionCaseId
						OR Caso__c = null
				)
			FROM Cobertura__c
			WHERE Contrato__c = :ContractId
			ORDER BY Name
		];

		if(coverages.size() > 0) {
			Set<Id> productIds = new Set<Id>();
			for(Cobertura__c cov : coverages) {
				productIds.add(cov.Producto__c);
			}

			List<Product2> allAdditionals = [
				SELECT Id, Numero__c, Sector__c, (
						SELECT Producto_principal__c
						FROM Adicional_para_productos__r
						WHERE Producto_principal__c IN :productIds
					)
				FROM Product2
				WHERE Id IN (
						SELECT Adicional__c
						FROM Adicional_de_producto__c
						WHERE Producto_principal__c IN :productIds
					)
			];
			Map<Id, List<Product2>> aditionalsByProduct = new Map<Id, List<Product2>>();
			for(Product2 additional : allAdditionals) {
				for(Adicional_de_producto__c relation : additional.Adicional_para_productos__r) {
					if(!aditionalsByProduct.containsKey(relation.Producto_principal__c)) {
						aditionalsByProduct.put(relation.Producto_principal__c, new List<Product2>());
					}
					aditionalsByProduct.get(relation.Producto_principal__c).add(additional);
				}
			}

			List<Servicio__c> allServices = [
				SELECT Id, Name, (
						SELECT Id, Producto__c
						FROM Servicios_de_Producto__r
						WHERE Producto__c IN :productIds
					)
				FROM Servicio__c
				WHERE Id IN (
						SELECT Servicio__c
						FROM Servicio_de_Producto__c
						WHERE Producto__c IN :productIds
					)
			];
			Map<Id, List<Servicio__c>> servicesByProduct = new Map<Id, List<Servicio__c>>();
			for(Servicio__c service : allServices) {
				for(Servicio_de_Producto__c relation : service.Servicios_de_Producto__r) {
					if(!servicesByProduct.containsKey(relation.Producto__c)) {
						servicesByProduct.put(relation.Producto__c, new List<Servicio__c>());
					}
					servicesByProduct.get(relation.Producto__c).add(service);
				}
			}

			Map<Id, List<Descuento_Recargo__c>> discountsByProduct = getDiscountsByProduct(productIds);

			for(lastWrapperIndex = 0; lastWrapperIndex < coverages.size(); lastWrapperIndex++) {
				ProductToAddWrapper prodWrapper = new ProductToAddWrapper(
						coverages[lastWrapperIndex],
						aditionalsByProduct.get(coverages[lastWrapperIndex].Producto__c),
						servicesByProduct.get(coverages[lastWrapperIndex].Producto__c),
						discountsByProduct.get(coverages[lastWrapperIndex].Producto__c),
						isPostSale,
						additionCaseId,
						lastWrapperIndex
					);
				Products.add(prodWrapper);
				AvailableProductsNames.remove(coverages[lastWrapperIndex].Producto__r.Numero__c);
			}
		}
	}

	public void simulatePrice() {
		simulation = null;

		for(ProductToAddWrapper pw : products) {
			if(!pw.discountsAreValid()) {
				return;
			}
		}

		simulation = new SimulationResult(
			ContractSAPSendSimulate.simulateProductPositions(ContractId, products)
		);
	}

	private void getAvailableProducts(String distributionChannel) {
		productsByName = new Map<String, Product2>();
		AvailableProductsNames = new Set<String>();
		for(Product2 prod : [
			SELECT Id, Numero__c, Sector__c
			FROM Product2
			WHERE IsActive = true
			AND Canal_de_Distribucion_2__c INCLUDES(:distributionChannel)
			AND (NOT Numero__c LIKE '% TRA')
		]) {
			if(prod.Numero__c != null) {
				String name = prod.Numero__c.replaceAll(' {2,}', ' ');
				//HACK When the list of names is displayed in a browser, multiple spaces
				// get transformed into one. This creates a problem when the browser
				// displays 'some prod name' but the controller is expecting 'some  prod name'
				// making it appear as if the product can't be added.
				productsByName.put(name, prod);
				AvailableProductsNames.add(name);
			}
		}
	}

	private void getContractId() {
		Id paramId = ApexPages.currentPage().getParameters().get('Id');
		if(paramId.getSObjectType() == Schema.Opportunity.SObjectType) {
			OpportunityId = paramId;

			Opportunity opp = [
				SELECT Id, Contrato__c
				FROM Opportunity
				WHERE Id = :OpportunityId
			];

			ContractId = opp.Contrato__c;
		}
		else {
			ContractId = paramId;
		}
		if(String.isBlank(ReturnRecord)) {
			ReturnRecord = paramId;
		}
		else {
			checkIsForAdditionCase();
		}
	}

	private Map<Id, List<Descuento_Recargo__c>> getDiscountsByProduct(Set<Id> productIds) {
		Set<Id> discountsForProducts = new Set<Id>();
		for(Descuento_Recargo_de_Producto__c drp : [
			SELECT Descuento_o_Recargo__c
			FROM Descuento_Recargo_de_Producto__c
			WHERE Producto__c IN :productIds
				AND Grupo_Vendedor__c INCLUDES (:userSalespersonGroup)
				AND (Tipo_de_cuenta__c = :accountType OR Tipo_de_cuenta__c = 'Todas')
		]) {
			discountsForProducts.add(drp.Descuento_o_Recargo__c);
		}

		List<Descuento_Recargo__c> allDiscounts = [
			SELECT Id, Name, Valor__c, Unidad__c, Codigo_de_descuento__c,
				Descuento_de_pos_venta__c, (
					SELECT Producto__c
					FROM Productos__r
					WHERE Producto__c IN :productIds
						AND Grupo_Vendedor__c INCLUDES (:userSalespersonGroup)
						AND (Tipo_de_cuenta__c = :accountType OR Tipo_de_cuenta__c = 'Todas')
				)
			FROM Descuento_Recargo__c
			WHERE Id IN :discountsForProducts
				OR Codigo_de_descuento__c = 'ZDV0'
				OR Codigo_de_descuento__c = 'ZDR0'
		];

		Map<Id, List<Descuento_Recargo__c>> discountsByProduct = new Map<Id, List<Descuento_Recargo__c>>();
		for(Descuento_Recargo__c discount : allDiscounts) {
			if(discount.Codigo_de_descuento__c == 'ZDV0' || discount.Codigo_de_descuento__c == 'ZDR0') {
							System.debug('s');
				for(Id productId : productIds) {
					if(!discountsByProduct.containsKey(productId)) {
						discountsByProduct.put(productId, new List<Descuento_Recargo__c>());
					}
					discountsByProduct.get(productId).add(discount);
				}
			}
			else {
				for(Descuento_Recargo_de_Producto__c relation : discount.Productos__r) {
					if(!discountsByProduct.containsKey(relation.Producto__c)) {
						discountsByProduct.put(relation.Producto__c, new List<Descuento_Recargo__c>());
					}
					discountsByProduct.get(relation.Producto__c).add(discount);
				}
			}
		}
		return discountsByProduct;
	}

	private void checkIsForAdditionCase() {
		if(ReturnRecord.getSObjectType() == Schema.Case.SObjectType) {
			Case theCase = [
				SELECT Id, RecordType.DeveloperName
				FROM Case
				WHERE Id = :ReturnRecord
			];
			Casos_Beneficiarios_Descuentos__c caseSettings = Casos_Beneficiarios_Descuentos__c.getValues(theCase.RecordType.DeveloperName);
			if(caseSettings != null && caseSettings.Id != null) {
				additionCaseId = ReturnRecord;
				AllowOnlyDiscounts = true;
			}
		}
	}


	//// Aca preparo descuentos para listas de seleccion
	private void prepareSelectOptions() {
		ivaTreatments = new List<SelectOption>();
		ivaTreatmentMap = new Map<String, String>();

		for(Schema.PicklistEntry ivaTreatment :
			Beneficiario__c.Tratamiento_IVA__c.getDescribe().getPicklistValues()
		) {
			ivaTreatments.add(new SelectOption(ivaTreatment.getValue(), ivaTreatment.getLabel()));
			ivaTreatmentMap.put(ivaTreatment.getValue(), ivaTreatment.getLabel());
		}

		provinceOptions = new List<SelectOption>();
		provinceMap = new Map<String, String>();

		for(Interlocutor_Provincia__c provinceSetting : Interlocutor_Provincia__c.getAll().values()) {
			provinceOptions.add(new SelectOption(provinceSetting.Codigo_SAP__c, provinceSetting.Name));
			provinceMap.put(provinceSetting.Codigo_SAP__c, provinceSetting.Name);
		}
	}

	//==============================================================================================

	public class ProductToAddWrapper extends ProductWrapper {
		public boolean ShowDetails {get; set;}
		public boolean ShowAditionals {get; set;}
		public boolean ShowDiscounts {get; set;}
		public boolean ShowServices {get; set;}
		public boolean ShowSimulation {get; set;}
		public boolean CanBeDeleted {get; set;}

		public List<SelectOption> AvailableDiscountOptions {get; set;}
		public String selectedDiscountType {get; set;}
		public Descuento_Recargo_Aplicado__c selectedDiscount {get; set;}
		public List<DiscountToAddWrapper> Discounts {get; set;}
		public List<Descuento_Recargo_Aplicado__c> DiscountsToBeDelete {get; set;}
		public integer discountToRemove {get; set;}

		public List<SimulationPosition> Positions {get; set;}
		public SimulationPosition nextPosition {get; set;}
		private Integer positionToRemove;



		public ProductToAddWrapper(
			Id ContractId,
			Product2 mainProduct,
			String userSalespersonGroup,
			String accountType,
			boolean isPostSale,
			Id additionCaseId,
			integer Index,
			Id ReturnRecord
		) {
		
			super(
				ContractId,
				mainProduct,
				userSalespersonGroup,
				accountType,
				Index,
				ReturnRecord
			);
			AvailableDiscounts = new Map<Id, Descuento_Recargo__c>();
			AvailableDiscountOptions = new List<SelectOption>();
			basicInit();

			DiscountsToBeDelete = new List<Descuento_Recargo_Aplicado__c>();
			selectedDiscount = new Descuento_Recargo_Aplicado__c();
			CanBeDeleted = true;

			if(DiscountsSo != null && !DiscountsSo.isEmpty()) {
				filterDiscounts(isPostSale, additionCaseId);
			}

		}

		public ProductToAddWrapper(
			Cobertura__c coverage,
			List<Product2> productAdditionals,
			List<Servicio__c> services,
			List<Descuento_Recargo__c> discounts,
			boolean isPostSale,
			Id additionCaseId,
			integer index
		) {
			super(
				coverage,
				productAdditionals,
				services,
				discounts,
				index
			);
			AvailableDiscounts = new Map<Id, Descuento_Recargo__c>();
			AvailableDiscountOptions = new List<SelectOption>();
			basicInit();
			DiscountsToBeDelete = new List<Descuento_Recargo_Aplicado__c>();
			selectedDiscount = new Descuento_Recargo_Aplicado__c();
			CanBeDeleted = !isPostSale;
			
			if(DiscountsSo != null && !DiscountsSo.isEmpty()) {
				filterDiscounts(isPostSale, additionCaseId);
			}

		}

		public void addDiscount() {
			selectedDiscount.Descuento_o_Recargo__c = selectedDiscountType;
			
			DiscountToAddWrapper discount = 
				new DiscountToAddWrapper(
					AvailableDiscounts.get(selectedDiscountType),
					selectedDiscount
				);
			discount.IsActive=true;
			discount.CanBeChanged=true;
			discount.index = Discounts.size()-1;
			Discounts.add(discount);

			selectedDiscount = new Descuento_Recargo_Aplicado__c(); 

			
			for (integer i = 0; i < Discounts.size() ; i++) {
				Discounts[i].index = i;
			}

		} 

		public void removeDiscount() {
			if(Discounts[discountToRemove].Relation.id != null) {
				DiscountsToBeDelete.add( Discounts[discountToRemove].Relation );
			}
			Discounts.remove( discountToRemove );

			for (integer i = 0; i < Discounts.size() ; i++) {
				Discounts[i].index = i;
			}

		} 

		public List<Descuento_Recargo_Aplicado__c> getDiscountsToSave(Id caseId) {
			List<Descuento_Recargo_Aplicado__c> result = new List<Descuento_Recargo_Aplicado__c>();
			for(DiscountToAddWrapper dwr : Discounts) {
				if(dwr.Relation.Id == null) {
					dwr.Relation.Producto_de_Contrato__c = Coverage.Id;

					if(dwr.Discount.Descuento_de_pos_venta__c) {
						dwr.relation.Caso__c = caseId;
					}
				}
				result.add(dwr.Relation);
			}
			return result;
		}

		public List<Descuento_Recargo_Aplicado__c> getDiscountsToDelete() {
			return DiscountsToBeDelete;
		}

		public void addPosition() {
			nextPosition.Index = Positions.size();
			Positions.add(nextPosition);
			nextPosition = new SimulationPosition();
		}

		public integer getPositionToRemove() {
			return positionToRemove;
		}

		public void setPositionToRemove(integer val) {
			positionToRemove = val;
		}

		public void removePosition() {
			Integer index = -1;
			for(Integer i = 0; i < Positions.size(); i++) {
				if(Positions[i].index == positionToRemove) {
					index = i;
					break;
				}
			}

			if(index != -1) {
				Positions.remove(index);
			}
		}

		public boolean discountsAreValid() {
			Map<Id, List<Descuento_Recargo_Aplicado__c>> discountsByType = new Map<Id, List<Descuento_Recargo_Aplicado__c>>();

			for(DiscountToAddWrapper dwr : Discounts) {
				if(dwr.discount.Codigo_de_descuento__c == 'ZDV0'
					|| dwr.discount.Codigo_de_descuento__c == 'ZDR0'
				) {
					if(dwr.Relation.Valor__c == null 
					|| dwr.Relation.Valor__c == 0 
					|| dwr.Relation.Fecha_inicio__c == null 
					|| dwr.Relation.Fecha_Fin__c == null ) {

						ApexPages.AddMessage(
							new ApexPages.Message(
								ApexPages.Severity.ERROR,
								'Se debe poner la fecha de inicio y el valor a los descuentos seleccionados.'
							)
						);
						return false;
					}
					if(dwr.Relation.valor__c != null || dwr.Relation.valor__c != 0) {
						if(dwr.Relation.valor__c <= 0) {
							ApexPages.AddMessage(
								new ApexPages.Message(
									ApexPages.Severity.ERROR,
									'Ningun descuento debe tener un valor menor a cero.'
								)
							);

							return false;
						}

						if(dwr.Relation.valor__c > 100) {
							ApexPages.AddMessage(
								new ApexPages.Message(
									ApexPages.Severity.ERROR,
									'Ningun descuento debe tener un valor mayor a 100%.'
								)
							);

							return false;
						}
					}

				}
				else if(dwr.Relation.Fecha_inicio__c == null || dwr.Relation.Fecha_Fin__c == null ) {
					ApexPages.AddMessage(
						new ApexPages.Message(
							ApexPages.Severity.ERROR,
							'Se debe colocar la fecha de inicio y fin a los descuentos seleccionados'
						)
					);
					return false;
				}

				if( !discountsByType.containsKey(dwr.Discount.id) ) {
					discountsByType.put(dwr.Discount.id, new List<Descuento_Recargo_Aplicado__c>() );
				}
				discountsByType.get(dwr.Discount.id).add(dwr.relation);

				if(dwr.Relation.Fecha_Fin__c != null && dwr.Relation.Fecha_Fin__c <= dwr.Relation.Fecha_inicio__c  ) {
					ApexPages.AddMessage(
						new ApexPages.Message(
							ApexPages.Severity.ERROR,
							'La fecha final no puede ser menor o igual que la inicial en ningun descuento.'
						)
					);
					return false;
				}
			}

			for(List<Descuento_Recargo_Aplicado__c> appliedDiscounts : discountsByType.values()) {
				if (appliedDiscounts.size() > 1 && !datesAreValid(appliedDiscounts)) {
					ApexPages.AddMessage(
						new ApexPages.Message(
							ApexPages.Severity.ERROR,
							'La fecha en los descuento no coincide.'
						)
					);
					return false;
				}
			}

			return true;
		}

		
		public boolean datesAreValid(List<Descuento_Recargo_Aplicado__c> appliedDiscounts) {
			Map<Date, Descuento_Recargo_Aplicado__c> discountByUniqueStartDate = new Map<Date, Descuento_Recargo_Aplicado__c>();

			for (Descuento_Recargo_Aplicado__c discount : appliedDiscounts) {
				if( discountByUniqueStartDate.containsKey(discount.Fecha_inicio__c) ) {
					return false;
				}
				discountByUniqueStartDate.put(discount.Fecha_inicio__c, discount);
			}
			
			List<Date> sortedStartDates = new List<Date>( discountByUniqueStartDate.keySet() );
			sortedStartDates.sort();

			List<Descuento_Recargo_Aplicado__c> orderDiscounts = new List<Descuento_Recargo_Aplicado__c>();
			for( Date d : sortedStartDates ) {
				orderDiscounts.add( discountByUniqueStartDate.get(d) );
			}

			for (integer i = 0 ; i < orderDiscounts.size()-1 ; i++) {
				if(  orderDiscounts[i+1].Fecha_inicio__c < orderDiscounts[i].Fecha_Fin__c ) {
					return false;
				}
			}
			return true;

		}

		protected override void prepareDiscounts(
			List<Descuento_Recargo__c> DiscountsSo,
			List<Descuento_Recargo_Aplicado__c> relations
		) {
			Discounts = new List<DiscountToAddWrapper>();
			this.DiscountsSo = DiscountsSo;

			if(DiscountsSo != null) {
				Map<Id, List<Descuento_Recargo_Aplicado__c>> relationsByDiscount = new Map<Id, List<Descuento_Recargo_Aplicado__c>>();

				if(relations != null) {
					for(Descuento_Recargo_Aplicado__c rel : relations) {
						if(!relationsByDiscount.containsKey(rel.Descuento_o_Recargo__c)) {
							relationsByDiscount.put(rel.Descuento_o_Recargo__c, new List<Descuento_Recargo_Aplicado__c>() );
						} 

						relationsByDiscount.get(rel.Descuento_o_Recargo__c).add(rel);
					}
				}

				
				List<DiscountToAddWrapper> customDiscountWrappers = new List<DiscountToAddWrapper>();
				for(Descuento_Recargo__c discount : DiscountsSo) {
					if(relationsByDiscount.containsKey(discount.Id))  {
						for (Descuento_Recargo_Aplicado__c appliedDiscount : relationsByDiscount.get(discount.Id)) { 
							if(discount.Codigo_de_descuento__c == 'ZDV0' || discount.Codigo_de_descuento__c == 'ZDR0') {
								customDiscountWrappers.add(
									new DiscountToAddWrapper(
										discount,
										appliedDiscount
									)
								);
							} else {
								Discounts.add(
									new DiscountToAddWrapper(
										discount,
										appliedDiscount
									)
								);
							}
						} 
					} 
				}
				if(customDiscountWrappers.size() != 0) {
					Discounts.addAll(customDiscountWrappers);
				}
			}
		}

		private void basicInit() {
			ShowDetails = false;
			ShowAditionals = false;
			ShowDiscounts = false;
			ShowServices = false;
			ShowSimulation = false;
			positionToRemove = -1;

			Positions = new List<SimulationPosition>();
			nextPosition = new SimulationPosition();
		}

		private void filterDiscounts(boolean isPostSale, Id additionCaseId) {
			System.debug(isPostSale);
			List<DiscountToAddWrapper> tempDiscounts = new List<DiscountToAddWrapper>();
			for(DiscountToAddWrapper dw : Discounts) {
				if(dw.Discount.Descuento_de_pos_venta__c == isPostSale) {
					dw.setAdditionCase(additionCaseId);
					tempDiscounts.add(dw);
				}
			}

			Discounts = tempDiscounts;

			for (integer i = 0; i < Discounts.size() ; i++) {
				Discounts[i].index = i;
			}

			for (Descuento_Recargo__c discount : DiscountsSo) {
				if(Discount.Descuento_de_pos_venta__c == isPostSale) {
					AvailableDiscounts.put(discount.Id, discount);
					AvailableDiscountOptions.add( new SelectOption(String.valueOf(Discount.id), Discount.Name ));
				}
			} 
		}
	}

	public class DiscountToAddWrapper extends ProductWrapper.DiscountWrapper {
		public boolean IsActive {get; set;}
		public boolean CanBeChanged {get; set;}
		public integer index {get; set;}
	

		public DiscountToAddWrapper(Descuento_Recargo__c discount, Descuento_Recargo_Aplicado__c relation) {
			super(discount, relation);
			IsActive = relation != null;
			if(!IsActive) {
				this.Relation = new Descuento_Recargo_Aplicado__c(
					Descuento_o_Recargo__c = Discount.Id
				);
			}
		}

		public void setAdditionCase(Id additionCaseId) {
			if(IsActive) {
				CanBeChanged = relation.Caso__c == additionCaseId;
			}
			else {
				Relation.Caso__c = additionCaseId;
				CanBeChanged = true;
			}
		}
	}

	public class SimulationResult {
		public List<SimulationPosition> positions {get; set;}
		public Decimal totalPrice {get; set;}
		public boolean failed {get; set;}
		public String errorMessage {get; set;}

		public SimulationResult(ContractSAPSendSimulate.ProductSimulationResult simResult) {
			failed = simResult.status.Tipo != 'S';
			if(!failed) {
				positions = simResult.positions;
				totalPrice = 0;
				for(SimulationPosition sp : positions) {
					totalPrice += sp.noIvaPrice + sp.priceIVA;
				}
			}
			else {
				errorMessage = simResult.status.Descripcion;
				System.debug(errorMessage);
			}
		}
	}
}