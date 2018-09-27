public class OpportunityTriggerHelper {
	private Beneficiario__c beneficiario { get; set; }
	private static List<Descuento_Recargo_Aplicado__c> appliedSpecialDiscounts = new List<Descuento_Recargo_Aplicado__c>();
	private static Boolean appliedSpecialDiscountsFound = false;
	
	class ContractNumberException extends Exception { }
	
	public static void createContracts(List<Opportunity> newOpps) {
		Map<String, LetterNumberPair> nextContractNumbers = getContractUniqueNumberByRecordType();
		Map<Id, User> salespersonsById = getSalespersonsById(newOpps);
		
		Map<integer, Contrato__c> contractsToInsert = new Map<integer, Contrato__c> ();
		Map<integer, Opportunity> opportunities = new Map<integer, Opportunity> ();
		Map<String, Id> contractRts = getContractRecordTypeIdByDevName();
		
		integer counter = 0;
		for (Opportunity opp : newOpps) {
			contractsToInsert.put(
				counter,
				createContractForOpportunity(
					opp,
					salespersonsById.get(opp.Vendedor__c),
					nextContractNumbers,
					contractRts
				)
			);
			opportunities.put(counter, opp);
			counter++;
		}
		if (contractsToInsert.size() != 0) {
			try {
				insert contractsToInsert.values();
			}
			catch(DmlException err) {
				if (err.getMessage().contains('DUPLICATE_VALUE')) {
					if (contractsToInsert.size() == 1) {
						List<Contrato__c> contracts = contractsToInsert.values();
						contracts[0].Numero_Unico_de_Contrato__c = nextNumberInCustomSetting(contracts[0].Numero_Unico_de_Contrato__c.subString(0, 1));
						insert contracts;
					} else {
						ContractNumberException ex = new ContractNumberException();
						ex.setMessage(
							'Existen números de contrato duplicados, aumente los valores de los numeros ' +
							'de contrato correspondientes en su configuración personalizada.'
						);
						throw ex;
					}
				}
				else {
					throw err;
				}
			}
			
			for (integer i : contractsToInsert.keySet()) {
				opportunities.get(i).Contrato__c = contractsToInsert.get(i).Id;
			}
		}
	}
	
	public static Map<id, List<id>> createCase(Opportunity opp, RecordType registro,
		Group owner, List<Beneficiario__c> objBeneficiario,
		List<Cobertura_de_Beneficiario__c> coberturaBeneficiario){

		Map<id, List<id>> nuevosPedidos = new Map<id, List<id>>();
		Case caseObj = new Case(
			RecordTypeId = registro.Id,
			Credencial__c = opp.Requiere_credencial__c ,
			Dispositivo__c = opp.Requiere_dispositivo__c,
			OwnerId = owner.Id,
			Contrato__c = opp.Contrato__c,
			forma_de_entrega__c = opp.forma_de_entrega__c,
			Reason = 'Entrega de Materiales',
			Oportunidad__c = opp.Id,
			Status = 'Nuevo'
		);

		insert caseObj;
		if(caseObj.Credencial__c){
			List<id> pedidos = searchForEmbozado(opp, caseObj,objBeneficiario,coberturaBeneficiario);
			nuevosPedidos.put(opp.AccountId, pedidos);
		}
		return nuevosPedidos;
	}

	
	public static void createEmbozado (List<Opportunity> opps) {
		Set<Id> createCase = new Set<Id>();
		Set<Id> createCredential = new Set<Id>();

		for (Opportunity opp : opps) {
			if(opp.Requiere_credencial__c || opp.Requiere_dispositivo__c){
				createCase.add(opp.id);
			}
		
			if(opp.Requiere_credencial_provisoria__c){
				createCredential.add(opp.id);
			}
		}

		if (createCase.size() > 0) {
			List<Cobertura_de_Beneficiario__c> coveragesToCreateCase = [
				SELECT Id, Beneficiario__c, 
					Cobertura__r.Requiere_credencial__c,
					Cobertura__r.Nombre_de_producto__c
				FROM Cobertura_de_Beneficiario__c
				WHERE Cobertura__r.Requiere_credencial__c = true
				AND Creado_en_Oportunidad__c IN :createCase
			];

			List<Id> recipientsToCreateCaseIds = new List<Id> ();
			for (Cobertura_de_Beneficiario__c b : coveragesToCreateCase) {
				recipientsToCreateCaseIds.add(b.Beneficiario__c);
			}

			List<Beneficiario__c> recipientsToCreateCase = [
				SELECT Id, Version__c, TRACK_1__c, TRACK_2__c,
				Numero_Club_de_Emergencias__c, Nombre__c, Apellido__c
				FROM Beneficiario__c
				WHERE Id IN :recipientsToCreateCaseIds
			];

			Group owner = [
				SELECT Id 
				FROM Group 
				WHERE Name = 'CAC-Logística'
			];

			RecordType registro = [
				SELECT Id 
				FROM RecordType 
				WHERE developerName = 'Pedido_a_CAC_Logistica' 
				LIMIT 1
			];


			Map<id, List<id>> nuevosPedidos = new Map<id, List<id>>();
			for (Opportunity opp : opps) {
				if(opp.Requiere_credencial__c || opp.Requiere_dispositivo__c){
					nuevosPedidos = createCase( opp,  registro,  owner, recipientsToCreateCase, coveragesToCreateCase);
				}
			}
		}

		// Ya habiendo creado los pedidos de embozado se llama al envio de correo al titular
		if (createCredential.size() > 0) {
			List<Cobertura_de_Beneficiario__c> coveragesToSendCredential = [
				SELECT id, Beneficiario__r.Contrato__c, Beneficiario__r.Version__c, 
					Beneficiario__r.TRACK_1__c,Beneficiario__r.TRACK_2__c, 
					Beneficiario__r.Numero_Club_de_Emergencias__c,
					Beneficiario__r.Nombre__c, Beneficiario__r.Apellido__c
				FROM Cobertura_de_Beneficiario__c
				WHERE Cobertura__r.Requiere_Credencial_Provisoria__c = True
				AND Beneficiario__r.RecordType.DeveloperName = 'Persona'
				AND Creado_en_Oportunidad__c IN :createCredential
			];

			if(SendCredential.canSendProvisoryCredential()) {
				SendCredential.sendCredentials(coveragesToSendCredential);
			}
		}
	}
	
	public static List<id> searchForEmbozado(Opportunity opp, Case caseOb, List<Beneficiario__c> objBeneficiario, List<Cobertura_de_Beneficiario__c> coberturaBeneficiario) {
		Configuracion_embozados__c config = Configuracion_embozados__c.getOrgDefaults();
		Integer proxNumero = (config.Ultimo_numero_credencial__c != null)  ? config.Ultimo_numero_credencial__c.intValue()+1 : 1;
		EmbozadoBuilder embozado = new EmbozadoBuilder(proxNumero);
		List<Pedido_de_Embozado__c> listaEmbozados = new List<Pedido_de_Embozado__c>();
		
		for(Beneficiario__c benef : objBeneficiario){
			for (Cobertura_de_Beneficiario__c covertura : coberturaBeneficiario) {
				if( benef.Id == covertura.Beneficiario__c){
					listaEmbozados.add(embozado.obtenerPedido(benef, covertura.Cobertura__r.Nombre_de_producto__c, caseOb.Id, 'Automático'));
				}
			}
		}
		
		config.Ultimo_numero_credencial__c = embozado.numero;
		upsert config;
		insert listaEmbozados;
		
		List<id> idEmbozados = new List<id>();
		for(Pedido_de_Embozado__c pedido : listaEmbozados){
			idEmbozados.add(pedido.id);
		}
		return idEmbozados;
	}
	
	public static void sendClientAndContract(List<Opportunity> opps) {
		for (Opportunity opp : opps) {
			String automatico = (opp.Tipo_de_Alta__c == 'Nueva') ? 'A' : 'M' ;
			system.debug(automatico);
			EverythingSenderQueueable esq = new EverythingSenderQueueable(
				opp.AccountId,
				opp.Contrato__c,
				automatico
			);
			System.enqueueJob(esq);
		}
	}
	
	public static void checkCommentOnRejection(Map<Id, Opportunity> opps) {
		List<Id> processInstanceIds = new List<Id> { };
		
		//get the Id of the last process instance of each opportunity
		for (Opportunity opp :[
			SELECT (
					SELECT Id
					FROM ProcessInstances
					ORDER BY CreatedDate DESC
					LIMIT 1
				)
			FROM Opportunity
			WHERE ID IN :opps.keySet()
		]) {
			processInstanceIds.add(opp.ProcessInstances[0].Id);
		}
		
		// Now that we have the most recent process instances, we can check
		// the most recent process steps for comments.
		for (ProcessInstance pi :[
			SELECT TargetObjectId, (
					SELECT Id, StepStatus, Comments
					FROM Steps
					WHERE StepStatus = 'Rejected' // DOBLE HACK, Comente la linea de abajo porque otros tipos de StepStatus se estaban colando en la lista,
					//WHERE StepStatus != 'Started'//HACK Added due to weird bug in the test where somehow the started was inserted after the rejected
					ORDER BY CreatedDate DESC
					LIMIT 1
				)
			FROM ProcessInstance
			WHERE Id IN :processInstanceIds
			ORDER BY CreatedDate DESC
		]) {
			System.debug(pi.Steps);
			if (String.isBlank(pi.Steps[0].Comments)) {
				opps.get(pi.TargetObjectId).addError(Label.No_se_dio_comentario_para_rechazo);
			}
		}
	}
	
	// public static void putRecordTypeToOpportunity(List<Opportunity> oppsCreatedByLead) {
	// 	Map<String, Id> recordTypeIdByDevName = new Map<String, Id>();
	// 	for(RecordType rt : getOpportunityTypesById().values()) {
	// 		recordTypeIdByDevName.put(rt.DeveloperName, rt.Id);
	// 	}
	//
	// 	for(Opportunity opp : oppsCreatedByLead) {
	// 		opp.RecordTypeId = recordTypeIdByDevName.get(opp.Tipo_de_oportunidad_por_prospecto__c);
	// 	}
	// }
	
	private static Contrato__c createContractForOpportunity(
		Opportunity opp,
		User salesperson,
		Map<String, LetterNumberPair> nextContractNumbers,
		Map<String, Id> contractRts
	) {
		Id ContractTypeId;
		LetterNumberPair contractNumber;
		if (opp.Venta_sin_contrato__c) {
			contractNumber = nextContractNumbers.get('X');
			ContractTypeId = contractRts.get('Ventas_Varias');
		}
		else {
			contractNumber = nextContractNumbers.get(opp.RecordTypeId);
			ContractTypeId = contractRts.get('Contrato');
		}
		
		Contrato__c result = new Contrato__c(
			Cliente__c = opp.AccountId,
			Estado__c = 'En proceso de venta',
			Numero_Unico_de_Contrato__c = contractNumber.getUniqueContractNumber(),
			RecordTypeId = ContractTypeId,
			Tipo_de_documento_SAP__c = opp.Tipo_de_documento_SAP__c
		);
		
		RecordType oppType = getOpportunityTypesById().get(opp.RecordTypeId);
		if(oppType.DeveloperName == 'Venta_Consumidor_Final') {
			result.Canal_de_Distribucion__c = getDistributionChannelValueForLabel('Consumidor Final');
		}
		else if(oppType.DeveloperName == 'Pymes') {
			result.Canal_de_Distribucion__c = getDistributionChannelValueForLabel('Pymes y Comercios');
		}
		
		contractNumber.ContractNum++;
		return result;
	}
	
	private static String getDistributionChannelValueForLabel(String dcLabel) {
		integer i = 0;
		List<Schema.PicklistEntry> distributionChannels = Contrato__c.Canal_de_Distribucion__c
			.getDescribe().getPicklistValues();
		while(distributionChannels[i].getLabel() != dcLabel) {
			i++;
		}
		return distributionChannels[i].getValue();
	}
	
	private static Map<Id, User> getSalespersonsById(List<Opportunity> opps) {
		Set<Id> userIds = new Set<Id> ();
		for (Opportunity opp : opps) {
			userIds.add(opp.Vendedor__c);
		}
		
		return new Map<Id, User> ([
			SELECT Id, Organizacion_de_Venta__c, Grupo_de_Vendedores__c
			FROM User
			WHERE Id IN :userIds
		]);
	}
	
	private static Map<String, LetterNumberPair> getContractUniqueNumberByRecordType() {
		List<RecordType> opportunityTypes = getOpportunityTypesById().values();
		
		Map<String, LetterNumberPair> nextContractNumberByLetter = new Map<String, LetterNumberPair> ();
		for (Numeros_de_contratos__c contractNumberSetting : Numeros_de_contratos__c.getAll().values()) {
			integer nextNum = 0;
			if (contractNumberSetting.Numero_maximo__c != null) {
				nextNum = (integer) (contractNumberSetting.Numero_maximo__c + 1);
			}
			nextContractNumberByLetter.put(
				contractNumberSetting.Name,
				new LetterNumberPair(
					contractNumberSetting.Name,
					nextNum
				)
			);
		}
		
		Map<String, LetterNumberPair> contractLeterByRecordType = new Map<String, LetterNumberPair> ();
		LetterNumberPair pairForSharedTypes = null;
		for (RecordType opportunityType : opportunityTypes) {
			if (opportunityType.DeveloperName == 'Venta_Consumidor_Final') {
				contractLeterByRecordType.put(
					opportunityType.Id,
					getNextContractNumberByLetter('D', nextContractNumberByLetter)
				);
			}
			else if (opportunityType.DeveloperName == 'Salud_y_Estado' || opportunityType.DeveloperName == 'Licitaci_n') {
				if (pairForSharedTypes == null) {
					pairForSharedTypes = getNextContractNumberByLetter('V', nextContractNumberByLetter);
				}
				contractLeterByRecordType.put(
					opportunityType.Id,
					pairForSharedTypes
				);
			}
			else if (opportunityType.DeveloperName == 'Corporaciones') {
				contractLeterByRecordType.put(
					opportunityType.Id,
					getNextContractNumberByLetter('C', nextContractNumberByLetter)
				);
			}
			else if (opportunityType.DeveloperName == 'Pymes') {
				contractLeterByRecordType.put(
					opportunityType.Id,
					getNextContractNumberByLetter('A', nextContractNumberByLetter)
				);
			}
		}
		contractLeterByRecordType.put(
			'X',
			getNextContractNumberByLetter('X', nextContractNumberByLetter)
		);

		return contractLeterByRecordType;
	}
	
	private static String nextNumberInCustomSetting(String letter) {
		System.debug('Llego');
		System.debug(letter);
		Numeros_de_contratos__c lastContractNumber = Numeros_de_contratos__c.getValues(letter);

		Set<Integer> contractNumbers = new Set<Integer> ();

		for (Contrato__c con :[
			SELECT Id, Numero_unico_de_contrato_numero__c
			FROM Contrato__c
			WHERE Numero_unico_de_contrato_numero__c > :(lastContractNumber.Numero_maximo__c)
				AND Numero_unico_de_contrato_numero__c < :(lastContractNumber.Numero_maximo__c + 10)
			LIMIT 10
		]) {
			contractNumbers.add((integer) con.Numero_unico_de_contrato_numero__c);
		}
		
		for (integer i = (integer)lastContractNumber.Numero_maximo__c + 1;
			i<(integer)lastContractNumber.Numero_maximo__c + 10;
			i++
		) {
			if (!contractNumbers.contains(i) || contractNumbers.isEmpty()) {
				System.debug(i);
				lastContractNumber.Numero_maximo__c = i;
				break;
			}
		}
		LetterNumberPair newContractNumber = new LetterNumberPair(letter, (integer) lastContractNumber.Numero_maximo__c);
		update lastContractNumber;
		return newContractNumber.getUniqueContractNumber();
	}
	
	private static Map<String, Id> getContractRecordTypeIdByDevName() {
		Map<String, Id> result = new Map<String, Id> ();
		
		for (RecordType rt :[
			SELECT Id, DeveloperName
			FROM RecordType
			WHERE IsActive = true
				AND SObjectType = 'Contrato__c'
		]) {
			result.put(rt.DeveloperName, rt.Id);
		}
		
		return result;
	}
	
	public static void activeRecipients(List<id> oppIds) {
		List<Beneficiario__c> recipients = [SELECT Id, Estado__c
			FROM Beneficiario__c
			WHERE Id IN (
					SELECT Beneficiario__c
					FROM Cobertura_de_beneficiario__c
					WHERE Creado_en_Oportunidad__c IN :oppIds
				)
		];
		for (Beneficiario__c recipient : recipients) {
			recipient.Estado__c='Activo';
		}
		update recipients;
	}
	
	private static LetterNumberPair getNextContractNumberByLetter(
		String letter, Map<String, LetterNumberPair> source
	) {
		LetterNumberPair result = source.get(letter);
		if (result == null) {
			result = new LetterNumberPair(letter, 1);
		}
		return result;
	}
	
	private static Map<Id, RecordType> oppTypes;
	private static Map<Id, RecordType> getOpportunityTypesById() {
		if(oppTypes == null) {
			oppTypes = new Map<Id, RecordType>([
				SELECT Id, DeveloperName
				FROM RecordType
				WHERE sObjectType = 'Opportunity'
			]);
		}
		return oppTypes;
	}

	public static void checkSpecialDiscountJustification (
		Map<Id, Opportunity> oppsForApprovalAndWithoutJustification
	) {
		//obtengo todos los productos de contrato con descuento a medida
		getAppliedSpecialDiscounts();

		Set<Id> coveragesWithSpecialDiscountApplied = new Set<Id>();
		for(Descuento_Recargo_Aplicado__c disc : appliedSpecialDiscounts) {
			coveragesWithSpecialDiscountApplied.add(disc.Producto_de_Contrato__c);
		}

		//obtengo las coberturas de benef. con prod. de contr. con descuento a medida
		List<Cobertura_de_Beneficiario__c> recipientCoveragesWithSpecialDiscount = [
			SELECT creado_en_oportunidad__r.Justificacion_de_descuentos_a_medida__c, cobertura__c 
			FROM cobertura_de_beneficiario__c
			WHERE creado_en_oportunidad__c IN : oppsForApprovalAndWithoutJustification.values()
			AND cobertura__c IN : coveragesWithSpecialDiscountApplied
		];

		//por cada cobertura con descuento a medida aplicado, tomo la opp padre y le agrego el error
		for (Cobertura_de_Beneficiario__c rc : recipientCoveragesWithSpecialDiscount) {
			oppsForApprovalAndWithoutJustification.get(rc.Creado_en_Oportunidad__c)
				.Justificacion_de_descuentos_a_medida__c.addError(
					Label.Oportunidad_Justificacion_por_descuento_a_medida_requerido
			);
		}
	}

	private static void getAppliedSpecialDiscounts() {
		if(!appliedSpecialDiscountsFound) {
			appliedSpecialDiscounts = [SELECT id, Producto_de_Contrato__c
				FROM Descuento_Recargo_Aplicado__c
				WHERE Descuento_o_Recargo__r.Codigo_de_descuento__c = 'ZDV0'
			];
			appliedSpecialDiscountsFound = true;
		}
	}
	
	class LetterNumberPair {
		public String Letter;
		public integer ContractNum;
		
		public LetterNumberPair(String l, integer n) {
			Letter = l;
			ContractNum = n;
		}
		
		public String getUniqueContractNumber() {
			String strNumber = String.valueOf(ContractNum);
			integer zerosToAdd = 6 - strNumber.length();
			for (Integer i = 0; i<zerosToAdd; i++) {
				strNumber = '0' + strNumber;
			}
			
			return Letter + strNumber;
		}
	}
}