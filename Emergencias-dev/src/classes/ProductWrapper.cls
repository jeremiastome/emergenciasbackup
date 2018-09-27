public abstract class ProductWrapper {
	//Wrapper class for products in AgregarProductos and MostrarServicios
	public integer Index {get; set;}
	public Cobertura__c Coverage {get; set;}
	public Map<Id, Product2> AvailableAdditionals {get; set;}
	public Map<Id, Descuento_Recargo__c> AvailableDiscounts {get; set;}
	public List<SelectOption> AdditionalsSelectOptions {get; set;}
	public Product2 MainProduct {get; set;}
	public List<Servicio__c> Services {get; set;}
	public List<Descuento_Recargo__c> DiscountsSo {get; set;}

	public List<String> SelectedAdditionals {
		get {
			if(Coverage != null && Coverage.Adicionales__c != null) {
				return Coverage.Adicionales__c.split(';');
			}
			else {
				return new List<String>();
			}
		}
		set {
			Coverage.Adicionales__c = '';
			if(value != null) {
				for(String s : value) {
					Coverage.Adicionales__c += s + ';';
				}
				Coverage.Adicionales__c = Coverage.Adicionales__c.left(Coverage.Adicionales__c.length() - 1);
			}
		}
	}
	
	//////////////////////////////////////////
	public ProductWrapper(
		Id ContractId,
		Product2 mainProduct,
		String userSalespersonGroup,
		String accountType,
		integer Index,
		Id ReturnRecord
	) {
		Coverage = new Cobertura__c(
			Contrato__c = ContractId,
			Producto__c = mainProduct.Id
		);
		this.Index = Index;
		this.MainProduct = mainProduct;
		//==========================================
		if(ReturnRecord != null) {
			if (ReturnRecord.getSObjectType().getDescribe().getName() == 'Case') {
				Coverage.Creado_en_Caso__c = ReturnRecord;
			}
			else if (ReturnRecord.getSObjectType().getDescribe().getName() == 'Opportunity') {
				Coverage.Creado_en_opp__c = ReturnRecord;
			}
		}
		//==========================================
		AvailableAdditionals = new Map<Id, Product2>([
			SELECT Id, Numero__c, Sector__c
			FROM Product2
			WHERE Id IN (
					SELECT Adicional__c
					FROM Adicional_de_producto__c
					WHERE Producto_principal__c = :mainProduct.Id
				)
		]);
		//==========================================
		Services = [
			SELECT Id, Name
			FROM Servicio__c
			WHERE Id IN (
					SELECT Servicio__c
					FROM Servicio_de_Producto__c
					WHERE Producto__c = :mainProduct.Id
				)
		];
		//==========================================
		Set<Id> discountIds = new Set<Id>();
		for(Descuento_Recargo_de_Producto__c drp : [
			SELECT Descuento_o_Recargo__c
			FROM Descuento_Recargo_de_Producto__c
			WHERE Producto__c = :mainProduct.Id
				AND Grupo_Vendedor__c INCLUDES (:userSalespersonGroup)
				AND (Tipo_de_cuenta__c = :accountType OR Tipo_de_cuenta__c = 'Todas')
		]) {
			discountIds.add(drp.Descuento_o_Recargo__c);
		}
		List<Descuento_Recargo__c> DiscountsSo = [
			SELECT Id, Name, Valor__c, Codigo_de_descuento__c, Descuento_de_pos_venta__c, Unidad__c
			FROM Descuento_Recargo__c
			WHERE Id IN :discountIds
				OR Codigo_de_descuento__c = 'ZDV0'
				OR Codigo_de_descuento__c = 'ZDR0'
		];
		
		prepareDiscounts(DiscountsSo, null);
		//==========================================
		generateSelectOptions();
	}
	
	public ProductWrapper(
		Cobertura__c coverage,
		List<Product2> productAdditionals,
		List<Servicio__c> services,
		List<Descuento_Recargo__c> discounts,
		integer index
	) {
		this.Index = index;
		this.Coverage = coverage;
		
		if(services != null) {
			this.Services = services;
		}
		else {
			this.Services = new List<Servicio__c>();
		}
		
		MainProduct = Coverage.Producto__r;
		if(productAdditionals != null) {
			AvailableAdditionals = new Map<Id, Product2>(productAdditionals);
		}
		else {
			AvailableAdditionals = new Map<Id, Product2>();
		}
		
		prepareDiscounts(discounts, coverage.Descuentos_Recargos_Aplicados__r);
		
		generateSelectOptions();
	}
	//==========================================================================
	
	public List<Cobertura__c> getAdditionals() {
		List<Cobertura__c> result = new List<Cobertura__c>();
		
		for(String addId : SelectedAdditionals) {
			Cobertura__c cov = new Cobertura__c(
				Producto__c = addId,
				Cantidad__c = Coverage.Cantidad__c
			);
			result.add(cov);
		}
		
		return result;
	}
	
	protected abstract void prepareDiscounts(
		List<Descuento_Recargo__c> DiscountsSo,
		List<Descuento_Recargo_Aplicado__c> relations
	);
	
	private void generateSelectOptions() {
		AdditionalsSelectOptions = new List<SelectOption>();
		for(Product2 prod : AvailableAdditionals.values()) {
			AdditionalsSelectOptions.add(new SelectOption(prod.Id, prod.Numero__c));
		}
	}
	
	public virtual class DiscountWrapper {
		public Descuento_Recargo__c Discount {get; set;}
		public Descuento_Recargo_Aplicado__c Relation {get; set;}
		
		public DiscountWrapper(Descuento_Recargo__c discount, Descuento_Recargo_Aplicado__c relation) {
			this.Discount = discount;
			this.Relation = relation;
		}
	}
}