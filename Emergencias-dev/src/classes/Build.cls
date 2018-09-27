@isTest
public class Build {

	//==========================================================================
	// ApplicantBuilder
	//==========================================================================

	public class ApplicantBuilder {
		private Aplicante__c obj = new Aplicante__c();

		public ApplicantBuilder forAppliedDiscount(Descuento_Recargo_Aplicado__c val) {
			obj.Descuento_Recargo_Aplicado__c = val.Id;
			return this;
		}

		public ApplicantBuilder forRecipientCoverage(Cobertura_de_Beneficiario__c val) {
			obj.Cobertura__c = val.Id;
			return this;
		}

		public ApplicantBuilder forCase(Case val) {
			obj.Caso__c = val.Id;
			return this;
		}

		public ApplicantBuilder withStartDate(Date val) {
			obj.Inicio_Vigencia__c = val;
			return this;
		}

		public ApplicantBuilder withEndDate(Date val) {
			obj.Fin_Vigencia__c = val;
			return this;
		}

		public Aplicante__c build() {
			return obj;
		}
	}

	public static ApplicantBuilder anApplicant() { return new ApplicantBuilder(); }

	//==========================================================================
	// AccountBuilder
	//==========================================================================
	static RecordType personAccountRecordType = [
		SELECT Id FROM RecordType
		WHERE DeveloperName = 'PersonAccount'
		AND SobjectType = 'Account'
	];
	static integer accountCount = 2;
	public class AccountBuilder {
		Account a;
		public AccountBuilder() {
			a = new Account();

			a.Phone = '2345678';
			a.CUIL_CUIT__c = getValidCuit('20' + String.valueOf(accountCount).leftPad(8, '0'));

			accountCount++;
		}

		public String getValidCuit(String cuitBase) {
			List<integer> serie = new List<integer> { 5, 4, 3, 2, 7, 6, 5, 4, 3, 2 };
			integer aux = 0;
			for (integer i = 0; i< 10; i++) {
				aux += Integer.valueOf(cuitBase.mid(i, 1)) * serie[i];
			}
			aux = 11 - Math.Mod(aux, 11);
			if (aux == 11 || aux == 10) {
				aux = 0;
			}
			return cuitBase + String.valueOf(aux);
		}

		public AccountBuilder withName(String value) {
			a.Name = value;
			return this;
		}


		public AccountBuilder isPersonAccount() {
			a.RecordTypeId = personAccountRecordType.Id;
			a.LastName = 'Test';
			a.FirstName = 'Man';
			return this;
		}

		public AccountBuilder withLastName(String value) {
			a.LastName = value;
			return this;
		}

		public AccountBuilder withFirstName(String value) {
			a.FirstName = value;
			return this;
		}

		public AccountBuilder withRandomCUILCUIT() {
			String firstChars = String.valueOf((Math.random() * 10000000).intValue()),
			nextChars = String.valueOf((Math.random() * 10000000).intValue());
			withCUILCUIT((firstChars + nextChars).substring(0, 11));
			return this;
		}

		public AccountBuilder withCUILCUIT(String value) {
			a.CUIL_CUIT__c = value;
			return this;
		}

		public AccountBuilder isPAU() {
			a.Es_PAU__c = true;
			a.Motivo_PAU__c = 'Some Cause';
			return this;
		}

		public AccountBuilder withNifType(String value) {
			a.Tipo_NIF__c = value;
			return this;
		}

		public AccountBuilder withSalutation(String value) {
			a.Salutation = value;
			return this;
		}

		public AccountBuilder withStatus(String value) {
			a.Estado__c = value;
			return this;
		}

		public AccountBuilder withPhone(String value) {
			a.Phone = value;
			return this;
		}

		public AccountBuilder withAlternativeFax(String value) {
			a.Fax_alternativo__c = value;
			return this;
		}

		public AccountBuilder withPersonEmail(String value) {
			a.PersonEmail = value;
			return this;
		}

		public AccountBuilder withBillingStreet(String value) {
			a.BillingStreet = value;
			return this;
		}

		public AccountBuilder withBillingCity(String value) {
			a.BillingCity = value;
			return this;
		}

		public AccountBuilder withBillingState(String value) {
			a.BillingState = value;
			return this;
		}

		public AccountBuilder withBillingPostalCode(String value) {
			a.BillingPostalCode = value;
			return this;
		}

		public AccountBuilder withBillingCountry(String value) {
			a.BillingCountry = value;
			return this;
		}

		public AccountBuilder withBillingLatitude(decimal value) {
			a.BillingLatitude = value;
			return this;
		}

		public AccountBuilder withBillingLongitude(decimal value) {
			a.BillingLongitude = value;
			return this;
		}

		public AccountBuilder withFloorApartment(String value) {
			a.Piso_depto__c = value;
			return this;
		}

		public AccountBuilder withTaxCondition(String val) {
			a.Condicion_IVA__c = val;
			return this;
		}

		public AccountBuilder withDocumentType(String val) {
			a.Tipo_de_Documento__c = val;
			return this;
		}

		public AccountBuilder withDocumentNumber(String val) {
			a.Numero_de_Documento__c = val;
			return this;
		}

		public AccountBuilder withBirthdate(Date val) {
			a.Fecha_de_nacimiento__c = val;
			return this;
		}

		public AccountBuilder withEmail(String value) {
			a.Correo_Electronico__c = value;
			return this;
		}

		public AccountBuilder withSkipSend(integer value) {
			a.Saltear_envio__c = value;
			return this;
		}

		public AccountBuilder availableToSendToSAP() {
			a.Dado_de_alta__c = true;
			return this;
		}

		public AccountBuilder withCompanyCode(String val) {
			a.Sociedad__c = val;
			return this;
		}

		public AccountBuilder withUniqueCustomerCode(String val) {
			a.N_mero_nico_de_Cliente__c = val;
			return this;
		}

		public AccountBuilder withSalesOrganization(String val) {
			a.Organizacion_de_Ventas__c = val;
			return this;
		}

		public AccountBuilder withDistributionChannel(String val) {
			a.Canal_de_Distribucion__c = val;
			return this;
		}

		public AccountBuilder withIVACondition(String val) {
			a.Condicion_IVA__c = val;
			return this;
		}

		public Account build() {
			if (a.RecordTypeId != personAccountRecordType.Id) {
				a.Name = 'Test S.A.';
			}
			return a;
		}
	}

	public static AccountBuilder anAccount() {
		return new AccountBuilder();
	}

	//==========================================================================
	// OpportunityBuilder
	//==========================================================================
	public class OpportunityBuilder {
		Opportunity o = new Opportunity(
			Name = 'Test Opp',
			CloseDate = System.today(),
			StageName = 'Pendiente de Rendir',
			Vendedor__c = UserInfo.getUserId(),
			Es_beneficiario__c = false
		);
		
		public OpportunityBuilder forAccount(Account value) {
			o.AccountId = value.Id;
			return this;
		}
		
		public OpportunityBuilder withSomeSalesHierarchy() {
			o.Grupo_de_Vendedores__c = 'Z2';
			o.Organizacion_de_Ventas__c = '0010';
			o.Canal_de_Distribucion__c = '30';
			o.Oficina_de_Venta__c = 'Z018';
			o.sociedad__c = '0010';
			return this;
		}
		
		public OpportunityBuilder withSalesperson(User value) {
			o.Vendedor__c = value.Id;
			return this;
		}
		
		public OpportunityBuilder withRecordTypeId(Id value) {
			o.RecordTypeId = value;
			return this;
		}
		
		public OpportunityBuilder withName(String value) {
			o.Name = value;
			return this;
		}
		
		public OpportunityBuilder withDischargeType(String value) {
			o.Tipo_de_Alta__c = value;
			return this;
		}
		
		public OpportunityBuilder withWarningJustification(String value) {
			o.Justificacion_para_Advertencias__c = value;
			return this;
		}
		
		public OpportunityBuilder withDischargeTypeNew() {
			o.Tipo_de_Alta__c = 'Nueva';
			return this;
		}
		
		public OpportunityBuilder withDischargeTypePartial() {
			o.Tipo_de_Alta__c = 'Parcial';
			return this;
		}
		
		public OpportunityBuilder withWarningsValidated() {
			o.Advertencias_validadas__c = true;
			return this;
		}
		
		public OpportunityBuilder withoutWarningsValidated() {
			o.Advertencias_validadas__c = false;
			return this;
		}
		
		public OpportunityBuilder withSellersGroup(String value) {
			o.Grupo_de_Vendedores__c = value;
			return this;
		}
		
		public OpportunityBuilder saleWithoutContract() {
			o.Venta_sin_contrato__c = true;
			return this;
		}
		
		public OpportunityBuilder forContract(Contrato__c contract) {
			o.Contrato__c = contract.Id;
			return this;
		}
		
		public OpportunityBuilder withSociety(String value) {
			o.Sociedad__c = value;
			return this;
		}
		
		public OpportunityBuilder withSalesOrganization(String value) {
			o.Organizacion_de_Ventas__c  = value;
			return this;
		}
		
		public OpportunityBuilder withDistributionChannel(String value) {
			o.Canal_de_Distribucion__c = value;
			return this;
		}
		
		public OpportunityBuilder withStageName(String value) {
			o.StageName = value;
			return this;
		}
		
		public Opportunity build() {
			if (o.AccountId == null) {
				Account a = anAccount().build();
				insert a;
				o.AccountId = a.Id;
			}
			return o;
		}
	}

	public static OpportunityBuilder anOpportunity() {
		return new OpportunityBuilder();
	}

	//==========================================================================
	// ZoneBuilder
	//==========================================================================
	public class ZoneBuilder {
		Zona__c z = new Zona__c();

		public ZoneBuilder withName(String value) {
			z.Name = value;
			return this;
		}

		public ZoneBuilder withType(String value) {
			z.Tipo__c = value;
			return this;
		}

		public ZoneBuilder withTypeConditionedAccess() {
			z.Tipo__c = 'Acceso condicionado';
			return this;
		}

		public ZoneBuilder withTypeCollector() {
			z.Tipo__c = 'Cobrador';
			return this;
		}

		public ZoneBuilder withPosition(String value) {
			z.Posicion__c = value;
			return this;
		}

		public ZoneBuilder withSAPName(String value) {
			z.Nombre_SAP__c = value;
			return this;
		}

		public ZoneBuilder withExternalId(String value) {
			z.ID_Externo__c = value;
			return this;
		}

		public Zona__c build() {
			return z;
		}
	}

	public static ZoneBuilder aZone() {
		return new ZoneBuilder();
	}

	//==========================================================================
	// CBUBuilder
	//==========================================================================
	public class CBUBuilder {
		CBU__c c = new CBU__c(
							  Name = '2850590940090418135201' //valid CBU
		);

		public CBUBuilder withName(String value) {
			c.Name = value;
			return this;
		}

		public CBU__c build() {
			return c;
		}
	}

	public static CBUBuilder aCBU() {
		return new CBUBuilder();
	}

	//==========================================================================
	// TarjetaBuilder
	//==========================================================================
	public class TarjetaBuilder {
		Tarjeta__c t = new Tarjeta__c(
									  Numero_de_tarjeta__c = '4398728045218854' //valid card number
		);

		public TarjetaBuilder withCardNumber(String value) {
			t.Numero_de_tarjeta__c = value;
			return this;
		}

		public Tarjeta__c build() {
			return t;
		}
	}

	public static TarjetaBuilder aCreditCard() {
		return new TarjetaBuilder();
	}

	//==========================================================================
	// PriceBookBuilder
	//==========================================================================
	public class PriceBookBuilder {
		Pricebook2 p = new Pricebook2(
									  Name = 'Test price book',
									  IsActive = true
		);

		public PriceBookBuilder withName(String value) {
			p.Name = value;
			return this;
		}

		public PriceBookBuilder notActive() {
			p.IsActive = false;
			return this;
		}

		public Pricebook2 build() {
			return p;
		}
	}

	public static PriceBookBuilder aPriceBook() {
		return new PriceBookBuilder();
	}

	//==========================================================================
	// ProductBuilder
	//==========================================================================
	public class ProductBuilder {
		Product2 p = new Product2(
								  Name = 'Test',
								  IsActive = true
		);

		public ProductBuilder withName(String value) {
			p.Name = value;
			return this;
		}

		public ProductBuilder withProductCode(String value) {
			p.ProductCode = value;
			return this;
		}

		public ProductBuilder withDistributionChannel(String value){
			p.Canal_de_Distribucion_2__c = value;
			return this;
		}

		public ProductBuilder withDescription(String value) {
			p.Description = value;
			return this;
		}

		public ProductBuilder withSalesOrganization(String value) {
			p.Organizacion_de_Venta__c = value;
			return this;
		}

		public ProductBuilder withNumber(String value) {
			p.Numero__c = value;
			return this;
		}

		public ProductBuilder withSector(String value) {
			p.Sector__c = value;
			return this;
		}

		public ProductBuilder needsCredential() {
			p.Requiere_envio_de_credencial__c = true;
			return this;
		}

		public Product2 build() {
			return p;
		}
	}

	public static ProductBuilder aProduct() {
		return new ProductBuilder();
	}

	//==========================================================================
	// PriceBookEntryBuilder
	//==========================================================================
	public class PriceBookEntryBuilder {
		PricebookEntry p = new PricebookEntry(
											  IsActive = true,
											  UnitPrice = 23.2,
											  UseStandardPrice = false
		);

		public PriceBookEntryBuilder forProduct(Product2 value) {
			p.Product2Id = value.Id;
			return this;
		}

		public PriceBookEntryBuilder forPriceBook(PriceBook2 value) {
			p.PriceBook2Id = value.Id;
			return this;
		}

		public PriceBookEntryBuilder withUnitPrice(decimal value) {
			p.UnitPrice = value;
			return this;
		}

		public PriceBookEntryBuilder withUnitPrice(integer value) {
			p.UnitPrice = (decimal) value;
			return this;
		}

		public PriceBookEntryBuilder notActive() {
			p.IsActive = false;
			return this;
		}

		public PriceBookEntryBuilder useStandardPrice() {
			p.UseStandardPrice = true;
			return this;
		}

		public PricebookEntry build() {
			if (p.PriceBook2Id == null) {
				p.PriceBook2Id = Test.getStandardPricebookId();
			}
			return p;
		}
	}

	public static PriceBookEntryBuilder aPriceBookEntry() {
		return new PriceBookEntryBuilder();
	}

	//==========================================================================
	// OpportunityLineItemBuilder
	//==========================================================================
	public class OpportunityLineItemBuilder {
		OpportunityLineItem o = new OpportunityLineItem();

		public OpportunityLineItemBuilder forPricebookEntry(PricebookEntry value) {
			o.PricebookEntryId = value.Id;
			return this;
		}

		public OpportunityLineItemBuilder forOpportunity(Opportunity value) {
			o.OpportunityId = value.Id;
			return this;
		}

		public OpportunityLineItemBuilder withQuantity(decimal value) {
			o.Quantity = value;
			return this;
		}

		public OpportunityLineItemBuilder withQuantity(integer value) {
			o.Quantity = (decimal) value;
			return this;
		}

		public OpportunityLineItemBuilder withDescription(String value) {
			o.Description = value;
			return this;
		}

		public OpportunityLineItemBuilder withDiscount(decimal value) {
			o.Discount = value;
			return this;
		}

		public OpportunityLineItemBuilder withPreAprovedDiscounts(String value) {
			o.Descuentos_pre_aprobados__c = value;
			return this;
		}

		public OpportunityLineItemBuilder withServiceDate(Date value) {
			o.ServiceDate = value;
			return this;
		}

		public OpportunityLineItemBuilder withUnitPrice(decimal value) {
			o.UnitPrice = value;
			return this;
		}

		public OpportunityLineItemBuilder withTotalPrice(decimal value) {
			o.TotalPrice = value;
			return this;
		}

		public OpportunityLineItem build() {
			return o;
		}
	}

	public static OpportunityLineItemBuilder anOpportunityLineItem() {
		return new OpportunityLineItemBuilder();
	}

	//==========================================================================
	// ContratoBuilder
	//==========================================================================
	static integer contractUniqueNumber = 1;
	public class ContratoBuilder {
		Contrato__c c = new Contrato__c();

		public ContratoBuilder forAccount(Account value) {
			c.Cliente__c = value.Id;
			return this;
		}

		public ContratoBuilder withRecordType(RecordType value) {
			c.RecordTypeId = value.Id;
			return this;
		}

		public ContratoBuilder withSalesperson(User value) {
			c.Vendedor__c = value.Id;
			return this;
		}

		public ContratoBuilder withCollector(Cobrador__c value) {
			c.Cobrador__c = value.Id;
			return this;
		}

		public ContratoBuilder withContactoCobranza(Contact value) {
			c.Contacto_Cobranza__c = value.Id;
			return this;
		}

		public ContratoBuilder withContactoDelivery(Contact value) {
			c.Contacto_de_delivery__c = value.Id;
			return this;
		}

		public ContratoBuilder withContactoFacturacion(Contact value) {
			c.Contacto_Facturacion__c = value.Id;
			return this;
		}

		public ContratoBuilder withUniqueNumber() {
			String num = String.valueOf(contractUniqueNumber);
			integer padding = 6 - num.length();
			for (Integer i = 0; i<padding; i++) {
				num = '0' + num;
			}

			c.Numero_unico_de_contrato__c = 'A' + num;
			contractUniqueNumber++;
			return this;
		}

		public ContratoBuilder withUniqueNumber(String value) {
			c.Numero_unico_de_contrato__c = value;
			return this;
		}

		public ContratoBuilder withUniqueNumberLetter(String value) {
			c.Numero_unico_de_contrato_letra__c = value;
			return this;
		}

		public ContratoBuilder withUniqueNumberWithSufix(String value) {
			c.Numero_Unico_de_Contrato_Con_Sufijo__c = value;
			return this;
		}

		public ContratoBuilder withStatus(String value) {
			c.Estado__c = value;
			return this;
		}

		public ContratoBuilder withCardNumber(String value) {
			c.Numero_de_Tarjeta__c = value;
			c.Tarjeta_sin_cifrar__c = value;
			return this;
		}

		public ContratoBuilder withCardName(String value) {
			c.Nombre_Impreso_de_Tarjeta__c = value;
			return this;
		}

		public ContratoBuilder withCardName() {
			c.Nombre_Impreso_de_Tarjeta__c = 'Potatomoto';
			return this;
		}

		public ContratoBuilder withValidCardNumber() {
			c.Numero_de_Tarjeta__c = '30123456789134';
			c.Tarjeta_sin_cifrar__c = '30123456789134';
			c.Nombre_Impreso_de_Tarjeta__c = 'TEST MANN';
			return this;
		}

		public ContratoBuilder withAnotherValidCardNumber() {
			c.Numero_de_Tarjeta__c = '5980289411573076';
			c.Tarjeta_sin_cifrar__c = '5980289411573076';
			c.Nombre_Impreso_de_Tarjeta__c = 'TEST GAL';
			return this;
		}

		public ContratoBuilder withCBU(String value) {
			c.CBU_cifrado__c = value;
			c.CBU__c = value;
			return this;
		}

		public ContratoBuilder withValidCBU() {
			c.CBU_cifrado__c = '2850100640094040123748';
			c.cbu__c = '2850100640094040123748';
			return this;
		}

		public ContratoBuilder withAnotherValidCBU() {
			c.CBU_cifrado__c = '0440024040000165916790';
			c.cbu__c = '0440024040000165916790';
			return this;
		}

		public ContratoBuilder withPaymentMethod(String value) {
			c.Forma_de_Pago__c = value;
			return this;
		}

		public ContratoBuilder withSkipSend(integer value) {
			c.Saltear_envio__c = value;
			return this;
		}

		public ContratoBuilder withSuffix(integer value) {
			c.Sufijo__c = value;
			return this;
		}

		public ContratoBuilder withCreditPaymentMethod() {
			c.Forma_de_Pago__c = 'A';
			return this;
		}

		public ContratoBuilder withDebitPaymentMethod() {
			c.Forma_de_Pago__c = 'S';
			return this;
		}

		public ContratoBuilder withActiveStatus() {
			c.Estado__c = 'Activo';
			return this;
		}

		public ContratoBuilder withPendingStatus() {
			c.Estado__c = 'En Proceso de Venta';
			return this;
		}

		public ContratoBuilder withSalesOrganization(String value) {
			c.Organizacion_de_Ventas__c = value;
			return this;
		}

		public ContratoBuilder withDistributionChannel(String value) {
			c.Canal_de_Distribucion__c = value;
			return this;
		}

		public ContratoBuilder withPaymentCondition(String value) {
			c.Condicion_de_pago__c = value;
			return this;
		}

		public ContratoBuilder withCardType(String value) {
			c.Tipo_de_Tarjeta__c = value;
			return this;
		}

		public ContratoBuilder withStartDate(Date value) {
			c.Fecha_Alta__c = value;
			return this;
		}

		public ContratoBuilder withEndDate(Date value) {
			c.Fecha_Baja__c = value;
			return this;
		}

		public ContratoBuilder isMassiveContract() {
			c.Contrato_de_Padrones__c = true;
			return this;
		}

		public ContratoBuilder withCollectorType(String value) {
			c.Tipo_de_Cobrador__c = value;
			return this;
		}

		public ContratoBuilder withCost(decimal value) {
			c.Importe__c = value;
			return this;
		}

		public ContratoBuilder withACollectorType() {
			c.Tipo_de_Cobrador__c = Contrato__c.Tipo_de_Cobrador__c.getDescribe().getPicklistValues() [0].getValue();
			return this;
		}

		public ContratoBuilder withSalesOffice(String value) {
			c.Oficina_de_Venta__c = value;
			return this;
		}

		public ContratoBuilder withSalesOffice() {
			c.Oficina_de_Venta__c = 'Z001';
			return this;
		}

		public ContratoBuilder withSalesGroup(String value) {
			c.Grupo_de_Vendedores__c = value;
			return this;
		}

		public ContratoBuilder withSalesGroup() {
			c.Grupo_de_Vendedores__c = 'Z2';
			return this;
		}

		public ContratoBuilder doesNotBill() {
			c.Forma_de_Facturaci_n__c = 'No Factura';
			return this;
		}

		public ContratoBuilder withSapDocumentType(String value) {
			c.Tipo_de_documento_sap__c = value;
			return this;
		}

		public ContratoBuilder withSapSendStatus(String value) {
			c.Estado_de_Envio_a_SAP__c = value;
			return this;
		}

		public ContratoBuilder notWaitingToBeSent() {
			c.Esperando_envio__c = false;
			return this;
		}

		public ContratoBuilder waitingToBeSent() {
			c.Esperando_envio__c = true;
			return this;
		}


		public Contrato__c build() {
			return c;
		}
	}

	public static ContratoBuilder aContract() {
		return new ContratoBuilder();
	}

	//==========================================================================
	// AdvertenciaBuilder
	//==========================================================================
	public class AdvertenciaBuilder {
		Advertencia__c a = new Advertencia__c(
											  Resuelto__c = false
		);

		public AdvertenciaBuilder withWarningType(String value) {
			a.Clase_de_advertencia__c = value;
			return this;
		}

		public AdvertenciaBuilder withWarningTypeDefault() {
			a.Clase_de_advertencia__c = 'Morosidad';
			return this;
		}

		public AdvertenciaBuilder withWarningTypeNotProfitable() {
			a.Clase_de_advertencia__c = 'Rentabilidad';
			return this;
		}

		public AdvertenciaBuilder withWarningTypePAU() {
			a.Clase_de_advertencia__c = 'PAU';
			return this;
		}

		public AdvertenciaBuilder withWarningTypeDangerousZone() {
			a.Clase_de_advertencia__c = 'Zona de acceso condicionado';
			return this;
		}

		public AdvertenciaBuilder withDetail(String value) {
			a.Detalle__c = value;
			return this;
		}

		public AdvertenciaBuilder solved() {
			a.Resuelto__c = true;
			return this;
		}

		public AdvertenciaBuilder forOpportunity(Opportunity value) {
			a.Oportunidad__c = value.Id;
			return this;
		}

		public Advertencia__c build() {
			return a;
		}
	}

	public static AdvertenciaBuilder aWarning() {
		return new AdvertenciaBuilder();
	}

	//==========================================================================
	// BeneficiarioBuilder
	//==========================================================================
	public class BeneficiarioBuilder {
		Beneficiario__c b = new Beneficiario__c(
			Provincia1__c = Beneficiario__c.Provincia1__c.getDescribe().getPicklistValues()[0].getValue()
		);

		public BeneficiarioBuilder forContract(Contrato__c value) {
			b.Contrato__c = value.Id;
			return this;
		}

		public BeneficiarioBuilder withContractId(Id value) {
			b.Contrato__c = value;
			return this;
		}

		public BeneficiarioBuilder forAccount(Account value) {
			b.Beneficiario__c = value.Id;
			return this;
		}

		public BeneficiarioBuilder forCase(Case value) {
			b.Caso__c = value.Id;
			return this;
		}

		public BeneficiarioBuilder forHolder(Titular__c value) {
			b.Titular__c = value.Id;
			return this;
		}

		public BeneficiarioBuilder withRecordType(RecordType value) {
			b.RecordTypeId = value.Id;
			return this;
		}

		public BeneficiarioBuilder withRecordTypeId(Id value) {
			b.RecordTypeId = value;
			return this;
		}

		public BeneficiarioBuilder forOpportunity(Opportunity value) {
			b.Oportunidad__c = value.Id;
			return this;
		}

		public BeneficiarioBuilder withUniqueCode(String val) {
			b.N_mero_nico_de_Beneficiario__c = val;
			return this;
		}

		public BeneficiarioBuilder withFixedPersonAmount(decimal val) {
			b.Cantidad_de_Personas_Fijas__c = val;
			return this;
		}

		public BeneficiarioBuilder withInTransitPersonAmount(decimal val) {
			b.Cantidad_de_personas_en_transito__c = val;
			return this;
		}

		public BeneficiarioBuilder withCensusDate(Date val) {
			b.Fecha_de_padron__c = val;
			return this;
		}

		public BeneficiarioBuilder withProvince(String val) {
			b.Provincia1__c = val;
			b.Provincia__c = val;
			return this;
		}

		public BeneficiarioBuilder withAddressCategory(String val) {
			b.Rubro_del_domicilio__c = val;
			return this;
		}

		public BeneficiarioBuilder withIVATreatment(String val) {
			b.Tratamiento_IVA__c = val;
			return this;
		}

		public BeneficiarioBuilder withStatus(String val) {
			b.Estado__c = val;
			return this;
		}

		public BeneficiarioBuilder withInactiveStatus() {
			b.Estado__c = 'Baja';
			return this;
		}

		public BeneficiarioBuilder withActiveStatus() {
			b.Estado__c = 'Activo';
			return this;
		}

		public Beneficiario__c build() {
			return b;
		}
	}

	public static BeneficiarioBuilder aRecipient() {
		return new BeneficiarioBuilder();
	}

	//==========================================================================
	// CoberturaBuilder
	//==========================================================================
	public class CoberturaBuilder {
		Cobertura__c c = new Cobertura__c();
		
		public CoberturaBuilder withName(string name) {
			c.Name = name;
			return this;
		}
		
		public CoberturaBuilder forContract(Contrato__c value) {
			c.Contrato__c = value.Id;
			return this;
		}
		
		public CoberturaBuilder forProduct(Product2 value) {
			c.Producto__c = value.Id;
			return this;
		}
		
		public CoberturaBuilder withQuantity(decimal value) {
			c.Cantidad__c = value;
			return this;
		}
		
		public CoberturaBuilder withPreAprovedDiscounts(String value) {
			c.Descuentos_pre_aprobados__c = value;
			return this;
		}
		
		public CoberturaBuilder withDiscount(decimal value) {
			//c.Descuento__c = value;
			return this;
		}
		
		public CoberturaBuilder withAditionals(String value) {
			c.Adicionales__c = value;
			return this;
		}

		public CoberturaBuilder withAmount(decimal value) {
			c.Cantidad__c = value;
			return this;
		}
		
		public CoberturaBuilder withMinorAmount(decimal value) {
			c.Cantidad_de_menores__c = value;
			return this;
		}
		
		public CoberturaBuilder withAmountInTransit(decimal value) {
			c.Cantidad_en_transito__c = value;
			return this;
		}
		
		public CoberturaBuilder createdInOpp(Opportunity value) {
			c.Creado_en_opp__c = value.id;
			return this;
		}
		
		public CoberturaBuilder needsProvisoryCredential() {
			c.Requiere_Credencial_Provisoria__c = True;
			return this;
		}
		
		public CoberturaBuilder createdInCase(Case value) {
			c.Creado_en_Caso__c = value.id;
			return this;
		}
		
		public Cobertura__c build() {
			return c;
		}
	}

	public static CoberturaBuilder aCoverage() {
		return new CoberturaBuilder();
	}

	//==========================================================================
	// CoberturaDeBeneficiarioBuilder
	//==========================================================================
	public class CoberturaDeBeneficiarioBuilder {
		Cobertura_de_Beneficiario__c c = new Cobertura_de_Beneficiario__c();

		public CoberturaDeBeneficiarioBuilder forRecipient(Beneficiario__c value) {
			c.Beneficiario__c = value.Id;
			return this;
		}

		public CoberturaDeBeneficiarioBuilder forCoverage(Cobertura__c value) {
			c.Cobertura__c = value.Id;
			return this;
		}

		public CoberturaDeBeneficiarioBuilder forCase(Case value) {
			c.Caso__c = value.Id;
			return this;
		}

		public CoberturaDeBeneficiarioBuilder createdInCase(Case value) {
			c.Creado_en_Caso__c = value.Id;
			return this;
		}

		public CoberturaDeBeneficiarioBuilder CreatedInOpp(Opportunity value) {
			c.Creado_en_Oportunidad__c = value.Id;
			return this;
		}

		public CoberturaDeBeneficiarioBuilder withIVATreatment(String value) {
			c.Tratamiento_de_IVA__c = value;
			return this;
		}

		public CoberturaDeBeneficiarioBuilder withIVATreatmentExempt() {
			c.Tratamiento_de_IVA__c = 'BE';
			return this;
		}

		public CoberturaDeBeneficiarioBuilder withAmountForMassiveRecipient(integer value) {
			c.Cantidad_de_Padron__c = value;
			return this;
		}
		
		public CoberturaDeBeneficiarioBuilder withDirectionAmount(decimal value) {
			c.Cantidad_domicilio__c = value;
			return this;
		}
		
		public CoberturaDeBeneficiarioBuilder withDirectionTransitAmount(decimal value) {
			c.Cantidad_domicilio_en_transito__c = value;
			return this;
		}

		public Cobertura_de_Beneficiario__c build() {
			return c;
		}
	}

	public static CoberturaDeBeneficiarioBuilder aCoverageRecipientRelation() {
		return new CoberturaDeBeneficiarioBuilder();
	}

	//==========================================================================
	// CredencialesEmergenciasBuilder
	//==========================================================================
	public class CredencialesEmergenciasBuilder {
		Credenciales_Emergencias__c c = new Credenciales_Emergencias__c(
																		Usuario__c = 'testman',
																		Contrasena__c = 'shhh its a secret',
																		Host__c = 'https://some.url.info/',
																		Path_incidentes__c = 'incidents/ws',
																		Path_cobradores__c = 'collectors/ws',
																		Path_zona_condicionada__c = 'zones/ws'
		);

		public CredencialesEmergenciasBuilder withUserName(String value) {
			c.Usuario__c = value;
			return this;
		}

		public CredencialesEmergenciasBuilder withPassword(String value) {
			c.Contrasena__c = value;
			return this;
		}

		public CredencialesEmergenciasBuilder withHost(String value) {
			c.Host__c = value;
			return this;
		}

		public CredencialesEmergenciasBuilder withIncidentsPath(String value) {
			c.Path_incidentes__c = value;
			return this;
		}

		public Credenciales_Emergencias__c build() {
			return c;
		}
	}

	public static CredencialesEmergenciasBuilder someEmergenciesCredentials() {
		return new CredencialesEmergenciasBuilder();
	}

	//==========================================================================
	// CaseBuilder
	//==========================================================================
	public class CaseBuilder {
		Case c = new Case();

		public CaseBuilder withOwner(Group value) {
			c.OwnerId = value.Id;
			return this;
		}

		public CaseBuilder withOwner(User value) {
			c.OwnerId = value.Id;
			return this;
		}

		public CaseBuilder forAccount(Account value) {
			c.AccountId = value.Id;
			return this;
		}

		public CaseBuilder forMasterCase(Case value) {
			c.Caso_maestro__c = value.Id;
			return this;
		}

		public CaseBuilder forParent(Case value) {
			c.ParentId = value.Id;
			return this;
		}

		public CaseBuilder forContract(Contrato__c value) {
			c.Contrato__c = value.Id;
			return this;
		}

		public CaseBuilder withClonedContract(Contrato__c value) {
			c.Contrato_clonado__c = value.Id;
			return this;
		}

		public CaseBuilder withReason(String value) {
			c.Reason = value;
			return this;
		}

		public CaseBuilder withRecordType(RecordType value) {
			c.RecordTypeId = value.Id;
			return this;
		}

		public CaseBuilder isClosed() {
			c.Status = 'Cerrado';
			return this;
		}

		public CaseBuilder WithCloseReason(String value) {
			c.Motivo_de_Finalizacion__c = value;
			return this;
		}

		public CaseBuilder WithBillNumber(String value) {
			c.Nro_de_Factura__c = value;
			return this;
		}

		public CaseBuilder WithBillReference(String value) {
			c.Con_referencia_a_factura__c = value;
			return this;
		}

		public CaseBuilder WithCreditNoteMotive(String value) {
			c.Motivo_de_nota_de_credito__c = value;
			return this;
		}

		public CaseBuilder withImpactDate(Date value) {
			c.Fecha_de_impacto__c = value;
			return this;
		}

		public Case build() {
			return c;
		}
	}

	public static CaseBuilder aCase() {
		return new CaseBuilder();
	}

	//==========================================================================
	// IncidenteBuilder
	//==========================================================================
	public class IncidenteBuilder {
		Incidente__c i = new Incidente__c();

		public IncidenteBuilder withClasification(String value) {
			i.Clasificacion__c = value;
			return this;
		}

		public IncidenteBuilder withDetails(String value) {
			i.Detalles__c = value;
			return this;
		}

		public IncidenteBuilder withStatus(String value) {
			i.Estado__c = value;
			return this;
		}

		public IncidenteBuilder withInstant(DateTime value) {
			i.Instante__c = value;
			return this;
		}

		public IncidenteBuilder withPatientName(String value) {
			i.Nombre_de_Paciente__c = value;
			return this;
		}

		public IncidenteBuilder withEntityNumber(String value) {
			i.Numero_de_Entidad__c = value;
			return this;
		}

		public IncidenteBuilder withServiceNumber(String value) {
			i.Numero_de_Servicio__c = value;
			return this;
		}

		public IncidenteBuilder forCase(Case value) {
			i.Caso__c = value.Id;
			return this;
		}

		public Incidente__c build() {
			return i;
		}
	}

	public static IncidenteBuilder anIncident() {
		return new IncidenteBuilder();
	}

	//==========================================================================
	// TitularBuilder
	//==========================================================================
	public class TitularBuilder {
		Titular__c t = new Titular__c(
			Ult_Numero_de_beneficiario__c = '000',
			Numero_de_Titular__c = '000'
		);
		
		public TitularBuilder forAccount(Account value) {
			t.Cliente__c = value.Id;
			return this;
		}
		
		public TitularBuilder forContract(Contrato__c value) {
			t.Contrato__c = value.Id;
			return this;
		}
		
		public TitularBuilder forOpportunity(Opportunity value) {
			t.Oportunidad__c = value.Id;
			return this;
		}
		
		public TitularBuilder withUniqueCode(String val) {
			t.Numero_de_Titular__c = val;
			return this;
		}
		
		public Titular__c build() {
			return t;
		}
	}

	public static TitularBuilder aHolder() {
		return new TitularBuilder();
	}

	//==========================================================================
	// AdicionalDeProductoBuilder
	//==========================================================================
	public class AdicionalDeProductoBuilder {
		Adicional_de_producto__c a = new Adicional_de_producto__c();

		public AdicionalDeProductoBuilder forMainProduct(Product2 value) {
			a.Producto_principal__c = value.Id;
			return this;
		}

		public AdicionalDeProductoBuilder forAdditionalProduct(Product2 value) {
			a.Adicional__c = value.Id;
			return this;
		}

		public Adicional_de_producto__c build() {
			return a;
		}
	}

	public static AdicionalDeProductoBuilder anAdditionalProductRelation() {
		return new AdicionalDeProductoBuilder();
	}

	//==========================================================================
	// ServicioBuilder
	//==========================================================================
	public class ServicioBuilder {
		Servicio__c s = new Servicio__c();

		public ServicioBuilder withName(String value) {
			s.Name = value;
			return this;
		}

		public ServicioBuilder withNumber(String value) {
			s.Numero__c = value;
			return this;
		}

		public Servicio__c build() {
			return s;
		}
	}

	public static ServicioBuilder aService() {
		return new ServicioBuilder();
	}

	//==========================================================================
	// ServicioDeProductoBuilder
	//==========================================================================
	static integer ServiceProductRelationUnique = 0;
	public class ServicioDeProductoBuilder {
		Servicio_de_Producto__c s = new Servicio_de_Producto__c(
																Id_Externo__c = 'text|text' + ServiceProductRelationUnique++
		);

		public ServicioDeProductoBuilder forProduct(Product2 value) {
			s.Producto__c = value.Id;
			return this;
		}

		public ServicioDeProductoBuilder forService(Servicio__c value) {
			s.Servicio__c = value.Id;
			return this;
		}

		public ServicioDeProductoBuilder withExternalId(String value) {
			s.Id_Externo__c = value;
			return this;
		}

		public Servicio_de_Producto__c build() {
			return s;
		}
	}

	public static ServicioDeProductoBuilder aServiceProductRelation() {
		return new ServicioDeProductoBuilder();
	}

	//==========================================================================
	// DescuentoRecargoBuilder
	//==========================================================================
	public class DescuentoRecargoBuilder {
		Descuento_Recargo__c d = new Descuento_Recargo__c();

		public DescuentoRecargoBuilder withName(String value) {
			d.Name = value;
			return this;
		}

		public DescuentoRecargoBuilder withValue(decimal value) {
			d.Valor__c = value;
			return this;
		}

		public DescuentoRecargoBuilder withUnit(String value) {
			d.Unidad__c = value;
			return this;
		}

		public DescuentoRecargoBuilder withDiscountCode(String value) {
			d.Codigo_de_descuento__c = value;
			return this;
		}

		public DescuentoRecargoBuilder isPostSaleDiscount() {
			d.Descuento_de_pos_venta__c = true;
			return this;
		}

		public Descuento_Recargo__c build() {
			return d;
		}
	}

	public static DescuentoRecargoBuilder aDiscount() {
		return new DescuentoRecargoBuilder();
	}

	//==========================================================================
	// DescuentoRecargoDeProductoBuilder
	//==========================================================================
	public class DescuentoRecargoDeProductoBuilder {
		Descuento_Recargo_de_Producto__c d = new Descuento_Recargo_de_Producto__c(
			Tipo_de_cuenta__c = 'Todas'
		);

		public DescuentoRecargoDeProductoBuilder forProduct(Product2 value) {
			d.Producto__c = value.Id;
			return this;
		}

		public DescuentoRecargoDeProductoBuilder forDiscount(Descuento_Recargo__c value) {
			d.Descuento_o_Recargo__c = value.Id;
			return this;
		}

		public DescuentoRecargoDeProductoBuilder withSalespersonGroup(String value) {
			d.Grupo_Vendedor__c = value;
			return this;
		}

		public DescuentoRecargoDeProductoBuilder forPersonAccounts() {
			d.Tipo_de_cuenta__c = 'Personal';
			return this;
		}

		public DescuentoRecargoDeProductoBuilder forEnterpriseAccounts() {
			d.Tipo_de_cuenta__c = 'Empresa';
			return this;
		}

		public DescuentoRecargoDeProductoBuilder forAllAccounts() {
			d.Tipo_de_cuenta__c = 'Todas';
			return this;
		}

		public Descuento_Recargo_de_Producto__c build() {
			return d;
		}
	}

	public static DescuentoRecargoDeProductoBuilder aDiscountProductRelation() {
		return new DescuentoRecargoDeProductoBuilder();
	}

	//==========================================================================
	// GroupBuilder
	//==========================================================================
	public class GroupBuilder {
		Group g = new Group();

		public GroupBuilder withName(String value) {
			g.Name = value;
			return this;
		}

		public GroupBuilder isQueue() {
			g.Type = 'Queue';
			return this;
		}

		public Group build() {
			return g;
		}
	}

	public static GroupBuilder aGroup() {
		return new GroupBuilder();
	}

	//==========================================================================
	// GroupMemberBuilder
	//==========================================================================
	public class GroupMemberBuilder {
		GroupMember g = new GroupMember();

		public GroupMemberBuilder forMember(User value) {
			g.UserOrGroupId = value.Id;
			return this;
		}

		public GroupMemberBuilder forMember(Group value) {
			g.UserOrGroupId = value.Id;
			return this;
		}

		public GroupMemberBuilder forGroup(Group value) {
			g.GroupId = value.Id;
			return this;
		}

		public GroupMember build() {
			return g;
		}
	}

	public static GroupMemberBuilder aGroupMembership() {
		return new GroupMemberBuilder();
	}
	//==========================================================================
	// QueueSobjectBuilder
	//==========================================================================
	public class QueueSobjectBuilder {
		QueueSobject q = new QueueSobject();

		public QueueSobjectBuilder forQueue(Group value) {
			q.QueueId = value.Id;
			return this;
		}

		public QueueSobjectBuilder forSObject(String value) {
			q.SobjectType = value;
			return this;
		}

		public QueueSobjectBuilder forSObjectCase() {
			q.SobjectType = 'Case';
			return this;
		}

		public QueueSobject build() {
			return q;
		}
	}

	public static QueueSobjectBuilder aQueueSobject() {
		return new QueueSobjectBuilder();
	}

	//==========================================================================
	// GruposParaCasosBuilder
	//==========================================================================
	public class GruposParaCasosBuilder {
		Grupos_para_casos__c g = new Grupos_para_casos__c(
														  Name = 'asd'
		);

		public GruposParaCasosBuilder forGroup(Group value) {
			g.Nombre_de_grupo__c = value.Name;
			return this;
		}

		public GruposParaCasosBuilder withUserField(String value) {
			g.Campo_en_usuario__c = value;
			return this;
		}

		public GruposParaCasosBuilder withName(String value) {
			g.Name = value;
			return this;
		}

		public Grupos_para_casos__c build() {
			return g;
		}
	}

	public static GruposParaCasosBuilder someGroupCaseAssignmentSettings() {
		return new GruposParaCasosBuilder();
	}

	//==========================================================================
	// UserBuilder
	//==========================================================================
	static integer userCode = 0;
	public class UserBuilder {
		User u;

		public UserBuilder() {
			String orgId = UserInfo.getOrganizationId();
			String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
			Integer randomInt = Integer.valueOf(math.rint(math.random() * 1000000));
			String uniqueName = orgId + dateString + randomInt + userCode;
			u = new User(
						 Alias = 'test' + userCode, Email = 'test' + userCode + '@noemail.com',
						 EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocalekey = 'en_US',
						 LocalesIdKey = 'en_US', country = 'United States', IsActive = true,
						 TimezonesIdKey = 'America/Los_Angeles', FirstName = 'Tester',
						 UserName = 'tester' + uniqueName + '@noemail.com'
			);
			userCode++;
		}

		public UserBuilder withTimezoneSIDKey(string value) {
			u.timezonesidkey = value;
			return this;
		}

		public UserBuilder withLocalesIdKey(string value) {
			u.localesidkey = value;
			return this;
		}

		public UserBuilder withLanguageLocalekey(string value) {
			u.LanguageLocalekey = value;
			return this;
		}

		public UserBuilder withContactId(string value) {
			u.ContactId = value;
			return this;
		}

		public UserBuilder withContact(Contact value) {
			u.ContactId = value.Id;
			return this;
		}

		public UserBuilder withProfileId(string value) {
			u.ProfileId = value;
			return this;
		}

		public UserBuilder withProfile(Profile value) {
			u.ProfileId = value.Id;
			return this;
		}

		public UserBuilder BeingActive(boolean value) {
			u.IsActive = value;
			return this;
		}

		public UserBuilder withAlias(string value) {
			u.Alias = value;
			return this;
		}

		public UserBuilder withEmail(string value) {
			u.Email = value;
			return this;
		}

		public UserBuilder withLastname(string value) {
			u.Lastname = value;
			return this;
		}

		public UserBuilder withUsername(string value) {
			u.Username = value;
			return this;
		}

		public UserBuilder withUserRole(UserRole value) {
			u.UserRoleId = value.Id;
			return this;
		}

		public UserBuilder withLastCaseLatePaymentAssignment(DateTime value) {
			u.Gestion_mora_ultima_asignacion__c = value;
			return this;
		}

		public UserBuilder withSalespersonGroup(String value) {
			u.Grupo_de_Vendedores__c = value;
			return this;
		}

		public UserBuilder withSalesOrganization(String value) {
			u.Organizacion_de_Venta__c = value;
			return this;
		}

		public User build() {
			if (u.ProfileId == null) {
				Profile prof = [SELECT Id FROM Profile LIMIT 1] [0];
				u.ProfileId = prof.Id;
			}

			return u;
		}
	}

	public static UserBuilder anUser() {
		return new UserBuilder();
	}

	//==========================================================================
	// ConfiguracionSapBuilder
	//==========================================================================
	public class ConfiguracionSapBuilder {
		Configuracion_SAP__c c = new Configuracion_SAP__c();

		public ConfiguracionSapBuilder withUrl(String value) {
			c.Url__c = value;
			return this;
		}

		public ConfiguracionSapBuilder withUsername(String value) {
			c.Usuario__c = value;
			return this;
		}

		public ConfiguracionSapBuilder withPassword(String value) {
			c.Contrasena__c = value;
			return this;
		}

		public Configuracion_SAP__c build() {
			return c;
		}
	}

	public static ConfiguracionSapBuilder SAPSettings() {
		return new ConfiguracionSapBuilder();
	}

	//==========================================================================
	// ConfigEmbozadoBuilder
	//==========================================================================

	public class ConfigEmbozadoBuilder{
	Configuracion_embozados__c c = new Configuracion_embozados__c();

		public ConfigEmbozadoBuilder withUltimoNumero(Integer numero){
			c.Ultimo_numero_credencial__c = numero;
			return this;
		}

		public ConfigEmbozadoBuilder withName(String Name){
			c.Name = Name;
			return this;
		}

		public Configuracion_embozados__c build() {
			return c;
		}
	}

	public static ConfigEmbozadoBuilder configEmbozado(){
		return new ConfigEmbozadoBuilder();
	}

	//==========================================================================
	// CasoGeneradorBuilder
	//==========================================================================
	public class CasoGeneradorBuilder {
		Caso_generador__c c = new Caso_generador__c();

		public CasoGeneradorBuilder forCaseRecordType(RecordType value) {
			c.Name = value.DeveloperName;
			return this;
		}

		public CasoGeneradorBuilder withCloseReasonCorrect(String value) {
			c.Motivo_cierre_correcto__c = value;
			return this;
		}

		public CasoGeneradorBuilder withCloseReasonIncorrect(String value) {
			c.Motivo_cierre_incorrecto__c = value;
			return this;
		}

		public Caso_generador__c build() {
			return c;
		}
	}

	public static CasoGeneradorBuilder someCaseContractCloneSettings() {
		return new CasoGeneradorBuilder();
	}

	//==========================================================================
	// ContactBuilder
	//==========================================================================
	public class ContactBuilder {
		Contact c = new Contact(
								LastName = 'Test',
								MailingCountry = 'Argentina',
								Provincia__C='Capital Federal'
		);

		public ContactBuilder forAccount(Account value) {
			c.AccountId = value.Id;
			return this;
		}

		public ContactBuilder withManualBillingZone(Zona__c value) {
			c.Zona_de_cobranza_manual__c = value.Id;
			return this;
		}

		public ContactBuilder withFirstName(String value) {
			c.FirstName = value;
			return this;
		}

		public ContactBuilder withLastName(String value) {
			c.LastName = value;
			return this;
		}

		public ContactBuilder withSkipSend(integer value) {
			c.Saltear_envio__c = value;
			return this;
		}

		public ContactBuilder withSalutation(String value) {
			c.Salutation = value;
			return this;
		}

		public ContactBuilder withMailingStreet(String value) {
			c.MailingStreet = value;
			return this;
		}

		public ContactBuilder withMailingCity(String value) {
			c.MailingCity = value;
			return this;
		}

		public ContactBuilder withMailingPostalCode(String value) {
			c.MailingPostalCode = value;
			return this;
		}

		public ContactBuilder withMailingCountry(String value) {
			c.MailingCountry = value;
			return this;
		}

		public ContactBuilder withMailingState(String value) {
			c.MailingState = value;
			return this;
		}

		public ContactBuilder withFloorApartment(String value) {
			c.Piso_depto__c = value;
			return this;
		}

		public Contact build() {
			return c;
		}
	}

	public static ContactBuilder aContact() {
		return new ContactBuilder();
	}

	//==========================================================================
	// CobradorBuilder
	//==========================================================================
	public class CobradorBuilder {
		Cobrador__c c = new Cobrador__c();

		public CobradorBuilder withName(String value) {
			c.Name = value;
			return this;
		}

		public CobradorBuilder withSAPCode(String value) {
			c.Codigo_Sap__c = value;
			return this;
		}

		public Cobrador__c build() {
			return c;
		}
	}

	public static CobradorBuilder aCollector() {
		return new CobradorBuilder();
	}

	//==========================================================================
	// DescuentoRecargoAplicadoBuilder
	//==========================================================================
	public class DescuentoRecargoAplicadoBuilder {
		Descuento_Recargo_Aplicado__c d = new Descuento_Recargo_Aplicado__c();

		public DescuentoRecargoAplicadoBuilder forDiscount(Descuento_Recargo__c value) {
			d.Descuento_o_Recargo__c = value.Id;
			return this;
		}

		public DescuentoRecargoAplicadoBuilder forCoverage(Cobertura__c value) {
			d.Producto_de_Contrato__c = value.Id;
			return this;
		}

		public DescuentoRecargoAplicadoBuilder forCase(Case value) {
			d.Caso__c = value.Id;
			return this;
		}

		public DescuentoRecargoAplicadoBuilder withStartDate(Date value) {
			d.Fecha_inicio__c = value;
			return this;
		}

		public DescuentoRecargoAplicadoBuilder withEndDate(Date value) {
			d.Fecha_Fin__c = value;
			return this;
		}

		public DescuentoRecargoAplicadoBuilder withAmountSubsidized(integer value) {
			d.Cantidad_de_Bonificados__c = value;
			return this;
		}

		public DescuentoRecargoAplicadoBuilder withValue(decimal value) {
			d.Valor__c = value;
			return this;
		}

		public Descuento_Recargo_Aplicado__c build() {
			return d;
		}
	}

	public static DescuentoRecargoAplicadoBuilder anAppliedDiscount() {
		return new DescuentoRecargoAplicadoBuilder();
	}

	//==========================================================================
	// InterlocutorProvinciaBuilder
	//==========================================================================
	public class InterlocutorProvinciaBuilder {
		Interlocutor_Provincia__c i = new Interlocutor_Provincia__c();

		public InterlocutorProvinciaBuilder withName(String value) {
			i.Name = value;
			return this;
		}

		public InterlocutorProvinciaBuilder withSAPCode(String value) {
			i.Codigo_SAP__c = value;
			return this;
		}

		public Interlocutor_Provincia__c build() {
			return i;
		}
	}

	public static InterlocutorProvinciaBuilder aProvinceSetting() {
		return new InterlocutorProvinciaBuilder();
	}

	//==========================================================================
	// GoogleSettingsBuilder
	//==========================================================================
	public class GoogleSettingsBuilder {
		Api_Key_Google_Maps__c a = new Api_Key_Google_Maps__c(
															  Key__c = '76tghu908uyh90ptyr78eu4jhtnj'
		);

		public GoogleSettingsBuilder withKey(String value) {
			a.Key__c = value;
			return this;
		}

		public Api_Key_Google_Maps__c build() {
			return a;
		}
	}

	public static GoogleSettingsBuilder someGoogleSettings() {
		return new GoogleSettingsBuilder();
	}

	//==========================================================================
	// CaseFutureContractActivationBuilder
	//==========================================================================
	public class CaseFutureContractActivationBuilder {
		Casos_activan_contrato_a_futuro__c c = new Casos_activan_contrato_a_futuro__c(
																					  Name = 'pepito'
		);

		public CaseFutureContractActivationBuilder withName(String value) {
			c.Name = value;
			return this;
		}

		public CaseFutureContractActivationBuilder withCaseType(String value) {
			c.Tipo_de_caso__c = value;
			return this;
		}

		public CaseFutureContractActivationBuilder withActivationValues(String value) {
			c.Valores_de_activacion__c = value;
			return this;
		}

		public Casos_activan_contrato_a_futuro__c build() {
			return c;
		}
	}

	public static CaseFutureContractActivationBuilder someCaseFutureContractActivationSettngs() {
		return new CaseFutureContractActivationBuilder();
	}

	//==========================================================================
	// AccountContactRelationBuilder
	//==========================================================================
	public class AccountContactRelationBuilder {
		AccountContactRelation a = new AccountContactRelation();

		public AccountContactRelationBuilder forAccount(Account value) {
			a.AccountId = value.Id;
			return this;
		}

		public AccountContactRelationBuilder forContact(Contact value) {
			a.ContactId = value.Id;
			return this;
		}

		public AccountContactRelation build() {
			return a;
		}
	}

	public static AccountContactRelationBuilder anAccountContactRelation() {
		return new AccountContactRelationBuilder();
	}

	//==========================================================================
	// ContractNumberBuilder
	//==========================================================================
	public class ContractNumberBuilder {
		Numeros_de_contratos__c n = new Numeros_de_contratos__c(
			Name = 'X',
			Numero_maximo__c = 123
		);

		public ContractNumberBuilder withLetter(String value) {
			n.Name = value;
			return this;
		}

		public ContractNumberBuilder withMaxNumber(integer value) {
			n.Numero_maximo__c = value;
			return this;
		}

		public Numeros_de_contratos__c build() {
			return n;
		}
	}

	public static ContractNumberBuilder aContractNumberSetting() {
		return new ContractNumberBuilder();
	}

	//==========================================================================
	// ProductoTransitoBuilder
	//==========================================================================
	public class ProductoTransitoBuilder {
		Producto_Transito__c p = new Producto_Transito__c();

		public ProductoTransitoBuilder withName(String value) {
			p.Name = value;
			return this;
		}

		public Producto_Transito__c build() {
			return p;
		}
	}

	public static ProductoTransitoBuilder aProductSeparationSetting() {
		return new ProductoTransitoBuilder();
	}

	//==========================================================================
	// CasosBeneficiariosDescuentosBuilder
	//==========================================================================
	public class CasosBeneficiariosDescuentosBuilder {
		Casos_Beneficiarios_Descuentos__c c = new Casos_Beneficiarios_Descuentos__c();

		public CasosBeneficiariosDescuentosBuilder forCaseRecordType(RecordType value) {
			c.Name = value.DeveloperName;
			return this;
		}

		public CasosBeneficiariosDescuentosBuilder withCloseReasonCorrect(String value) {
			c.Motivo_cierre_correcto__c = value;
			return this;
		}

		public CasosBeneficiariosDescuentosBuilder withCloseReasonIncorrect(String value) {
			c.Motivo_cierre_incorrecto__c = value;
			return this;
		}

		public Casos_Beneficiarios_Descuentos__c build() {
			return c;
		}
	}

	public static CasosBeneficiariosDescuentosBuilder someAdditionCaseSettings() {
		return new CasosBeneficiariosDescuentosBuilder();
	}

	//==========================================================================
	// TaskBuilder
	//==========================================================================
	public class TaskBuilder {
		Task t = new Task();

		public TaskBuilder withDueDate(DateTime value) {
			t.Fecha_de_vencimiento__c = value;
			return this;
		}

		public Task build() {
			return t;
		}
	}

	public static TaskBuilder aTask() {
		return new TaskBuilder();
	}

	//==========================================================================
	// CuentaCotizadorBuilder
	//==========================================================================
	public class CuentaCotizadorBuilder {
		Cuenta_de_cotizador__c c = new Cuenta_de_cotizador__c(
			Numero_unico_CF__c = '3456789999'
		);

		public CuentaCotizadorBuilder withFinalConsumerUniqueNumber(String value) {
			c.Numero_unico_CF__c = value;
			return this;
		}

		public Cuenta_de_cotizador__c build() {
			return c;
		}
	}

	public static CuentaCotizadorBuilder someSimulationAccountSettings() {
		return new CuentaCotizadorBuilder();
	}
	
	//==========================================================================
	// HolderNumberBuilder
	//==========================================================================
	public class HolderNumberBuilder {
		Numeros_de_Titulares__c n = new Numeros_de_Titulares__c(
			Name = 'X',
			Numero_maximo__c = 123
		);

		public HolderNumberBuilder withLetter(String value) {
			n.Name = value;
			return this;
		}

		public HolderNumberBuilder withMaxNumber(integer value) {
			n.Numero_maximo__c = value;
			return this;
		}

		public Numeros_de_Titulares__c build() {
			return n;
		}
	}

	public static HolderNumberBuilder aHolderNumberSetting() {
		return new HolderNumberBuilder();
	}
	
	//==========================================================================
	// AmountDetailBuilder
	//==========================================================================
	public class AmountDetailBuilder {
		Cantidad_de_producto_de_beneficiaro__c c = new Cantidad_de_producto_de_beneficiaro__c(
			Activo__c = false
		);
		
		public AmountDetailBuilder forRecipientCoverageRelation(Cobertura_de_Beneficiario__c value) {
			c.Cobertura_de_Beneficiario__c = value.Id;
			return this;
		}
		
		public AmountDetailBuilder forOpportunity(Opportunity value) {
			c.Oportunidad__c = value.Id;
			return this;
		}
		
		public AmountDetailBuilder withAmount(Integer value) {
			c.Cantidad__c = value;
			return this;
		}
		
		public AmountDetailBuilder withTransitAmount(Integer value) {
			c.Cantidad_en_transito__c = value;
			return this;
		}
		
		public AmountDetailBuilder isActive() {
			c.Activo__c = true;
			return this;
		}
		
		public AmountDetailBuilder isInactive() {
			c.Activo__c = false;
			return this;
		}
		
		public Cantidad_de_producto_de_beneficiaro__c build() {
			return c;
		}
	}
	
	public static AmountDetailBuilder anAmountDetail() {
		return new AmountDetailBuilder();
	}
}