public class MostrarServiciosController {
	public List<ProductToShowWrapper> Products {get; set;}
	public List<Descuento_Recargo_Aplicado__c> applyCoveragesDiscounts{get;set;}
	public Id ContractId {get; set;}
	public Id AccountId {get; set;}
	public Id RecipientId {get; set;}
	
	public MostrarServiciosController() {
		Id mainId = ApexPages.currentPage().getParameters().get('Id');
		String sObjName = mainId.getSObjectType().getDescribe().getName();
		if(sObjName=='Contrato__c') {
			ContractId = mainId;
		} else if (sObjName=='Beneficiario__c') {
			RecipientId = mainId;
        } else if (sObjName=='Account') {
            AccountId = mainId;
        }
	}
	
	public void regenerateOpportunityLineItems() {
		List<Cobertura__c> coverages = new List<Cobertura__c>();
		if (ContractId!=null) {
			coverages = [
				SELECT Id, Adicionales__c, Descuento__c, Cantidad__c, Cantidad_de_menores__c,
					Producto__c, Producto__r.Numero__c, (
						SELECT Id, Fecha_Fin__c, Fecha_inicio__c, Codigo_de_descuento__c,
							Cantidad_de_Bonificados__c, Caso__c, Valor__c, Nombre_de_descuento__c,
							Descuento_o_Recargo__c, Descuento_o_Recargo__r.Name,
							Descuento_o_Recargo__r.Valor__c, Descuento_o_Recargo__r.Codigo_de_descuento__c,
							Descuento_o_Recargo__r.Descuento_de_pos_venta__c, Descuento_o_Recargo__r.Unidad__c
						FROM Descuentos_Recargos_Aplicados__r
						WHERE Caso__c = null
					)
				FROM Cobertura__c
				WHERE Contrato__c = :ContractId
				ORDER BY Name
			];
		} else if (RecipientId!=null) {
			List<Cobertura_de_Beneficiario__c> recipientCoverageRelation = [
				SELECT Cobertura__c
				FROM Cobertura_de_Beneficiario__c
				WHERE Beneficiario__c=:RecipientId
			];
			List<Id> coverageIds = new List<Id>();
			for (Cobertura_de_Beneficiario__c relation : recipientCoverageRelation) {
				coverageIds.add(relation.Cobertura__c);
			}

			coverages = [
			SELECT Id, Adicionales__c, Descuento__c, Cantidad__c, Cantidad_de_menores__c,
				Producto__c, Producto__r.Numero__c, (
					SELECT Id, Fecha_Fin__c, Fecha_inicio__c, Codigo_de_descuento__c,
						Cantidad_de_Bonificados__c, Caso__c, Valor__c, Nombre_de_descuento__c,
						Descuento_o_Recargo__c, Descuento_o_Recargo__r.Name,
						Descuento_o_Recargo__r.Valor__c, Descuento_o_Recargo__r.Codigo_de_descuento__c,
						Descuento_o_Recargo__r.Descuento_de_pos_venta__c, Descuento_o_Recargo__r.Unidad__c
					FROM Descuentos_Recargos_Aplicados__r
					WHERE Caso__c = null
				)
			FROM Cobertura__c
			WHERE Id IN :coverageIds
			ORDER BY Name
			];

		}
		Products = new List<ProductToShowWrapper>();
		if(coverages.size() > 0) {
			Set<Id> productIds = new Set<Id>();
			Set<String> allAdditionalIds = new Set<String>();
			for(Cobertura__c cov : coverages) {
				productIds.add(cov.Producto__c);
				if(cov.Adicionales__c != null) {
					allAdditionalIds.addAll(cov.Adicionales__c.split(';'));
				}
			}
			
			List<Product2> allAdditionals = [
				SELECT Id, Numero__c, (
						SELECT Producto_principal__c
						FROM Adicional_para_productos__r
						WHERE Producto_principal__c IN :productIds
					)
				FROM Product2
				WHERE Id IN :allAdditionalIds
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
			
			for(integer i = 0; i < coverages.size(); i++) {
				List<Descuento_Recargo__c> discounts = new List<Descuento_Recargo__c>();
				for(Descuento_Recargo_Aplicado__c discount : coverages[i].Descuentos_Recargos_Aplicados__r) {
					//HACK Set the post sale flag to false so that all discounts are shown.
					discount.Descuento_o_Recargo__r.Descuento_de_pos_venta__c = false;
					discounts.add(discount.Descuento_o_Recargo__r);
				}
				
				ProductToShowWrapper wrapper = new ProductToShowWrapper(
					coverages[i],
					aditionalsByProduct.get(coverages[i].Producto__c),
					servicesByProduct.get(coverages[i].Producto__c),
					discounts,
					i
				);
				Products.add(wrapper);
			}
		}
	}
	
	public class ProductToShowWrapper extends ProductWrapper {
		public List<DiscountToShowWrapper> Discounts {get; set;}
		
		public ProductToShowWrapper(
			Cobertura__c coverage,
			List<Product2> productAdditionals,
			List<Servicio__c> services,
			List<Descuento_Recargo__c> discounts,
			integer index
		) {
			super(
				coverage,
				productAdditionals,
				services,
				discounts,
				index
			);
		}
		
		protected override void prepareDiscounts(
			List<Descuento_Recargo__c> DiscountsSo,
			List<Descuento_Recargo_Aplicado__c> relations
		) {
			Discounts = new List<DiscountToShowWrapper>();
			if(DiscountsSo != null) {
				Map<Id, Descuento_Recargo_Aplicado__c> relationsByDiscount = new Map<Id, Descuento_Recargo_Aplicado__c>();
				if(relations != null) {
					for(Descuento_Recargo_Aplicado__c rel : relations) {
						relationsByDiscount.put(rel.Descuento_o_Recargo__c, rel);
					}
				}
				
				List<DiscountToShowWrapper> customDiscountWrappers = new List<DiscountToShowWrapper>();
				for(Descuento_Recargo__c discount : DiscountsSo) {
					if(discount.Codigo_de_descuento__c == 'ZDV0' || discount.Codigo_de_descuento__c == 'ZDR0') {
						customDiscountWrappers.add(
							new DiscountToShowWrapper(
								discount,
								relationsByDiscount.get(discount.Id)
							)
						);
					}
					else {
						Discounts.add(
							new DiscountToShowWrapper(
								discount,
								relationsByDiscount.get(discount.Id)
							)
						);
					}
				}
				if(customDiscountWrappers.size() != 0) {
					Discounts.addAll(customDiscountWrappers);
				}
			}
		}
	}
	
	public class DiscountToShowWrapper extends ProductWrapper.DiscountWrapper {
		//TODO put Applicants
		
		public DiscountToShowWrapper(Descuento_Recargo__c discount, Descuento_Recargo_Aplicado__c relation) {
			super(discount, relation);
		}
	}
}