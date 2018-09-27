public class Vista360Controller {
	@AuraEnabled
	public static EstadoDeCuenta obtenerEstadoCuenta(String idCliente, String idSociedad) {

		return EstadoDeCuentaCliente.obtener(
			new Account(N_mero_nico_de_Cliente__c = idCliente, Sociedad__c = idSociedad),
			Date.today().addYears(-1),
			Date.today()
		);
	}

    @AuraEnabled
   public static EstadoDeCuenta obtenerEstadoContrato(String idCliente, String idSociedad, String numContrato) {
       System.debug(idCliente);

       Account cliente = [SELECT Id, N_mero_nico_de_Cliente__c, Sociedad__c
                          FROM Account
                          WHERE Id=:idCliente][0];


       EstadoDeCuenta estadoDeContrato = EstadoDeCuentaCliente.obtener(
			cliente,
			Date.today().addYears(-1),
			Date.today()
	   );
       for (integer i=0;estadoDeContrato.documentos.size()>i; i++) {
           if(estadoDeContrato.documentos[i].numeroDeContrato!=numContrato) {
           		  estadoDeContrato.documentos.remove(i);
           }
       }

       return estadoDeContrato;
    }

	@AuraEnabled
	public static DocumentoContable obtenerDetallesDocumento(String nroDocumento) {
		return EstadoDeCuentaCliente.obtenerDetalles(nroDocumento);
	}

	@AuraEnabled
	public static LegacySystemServiceList obtenerServiciosConsumidos(String idCliente) {
		return obtenerServiciosConsumidos(idCliente, null, null);
	}

	@AuraEnabled
	public static LegacySystemServiceList obtenerServiciosConsumidos(String idCliente, DateTime dateFrom, DateTime dateTo) {
		LegacySystemServiceList serviceList = new LegacySystemServiceList();

		String[] clavesDeSistema = obtenerClavesDeSistemaDeCliente(idCliente);

		LegacySystemServiceList legacySystemServiceList =
			WSEmergencias.getLegacySystemServiceList(clavesDeSistema, dateFrom, dateTo);
		return legacySystemServiceList;
	}

	@AuraEnabled
	public static TicketsHistoricosCliente obtenerTicketsHistoricos(String idCliente) {
		TicketsHistoricosCliente tickets = new TicketsHistoricosCliente();

		String[] clavesDeSistema = obtenerClavesDeSistemaDeCliente(idCliente);

		return WSEmergencias.getTicketsServiceListResponse(clavesDeSistema);
	}

	@testVisible
	public static String[] obtenerClavesDeSistemaDeCliente(Id idCliente) {
		String[] clavesSistema = new String[]{};

		List<Account> clientes = new List<Account>([
			SELECT Id,
				(SELECT Clave_Sistema_Contrato__c FROM Contratos__r),
				(SELECT Clave_Sistema_Titular__c FROM Titulares__r),
				(SELECT Clave_Sistema_Beneficiario_2__c FROM Beneficiarios__r)
			FROM Account
			WHERE Id = :idCliente
		]);

		if (clientes.isEmpty()) return clavesSistema;

		Boolean tieneContratos = clientes[0].Contratos__r != null && !clientes[0].Contratos__r.isEmpty();
		Boolean tieneTitulares = clientes[0].Titulares__r != null && !clientes[0].Titulares__r.isEmpty();
		Boolean tieneBeneficiarios = clientes[0].Beneficiarios__r != null && !clientes[0].Beneficiarios__r.isEmpty();

		// Es solo cliente
		if (tieneContratos) {
			for (Contrato__c contrato : clientes[0].Contratos__r) {
				clavesSistema.add(contrato.Clave_Sistema_Contrato__c);
			}
		} // Es solo titular
		else if (!tieneContratos && tieneTitulares && !tieneBeneficiarios) {
			Set<Id> idsTitulares = new Set<Id>();
			for (Titular__c titular : clientes[0].Titulares__r) {
				idsTitulares.add(titular.Id);
			}

			List<Beneficiario__c> beneficiariosDelTitular = new List<Beneficiario__c>([
				SELECT Clave_Sistema_Beneficiario_2__c
				FROM Beneficiario__c
				WHERE Titular__c IN :idsTitulares
			]);

			for (Beneficiario__c beneficiario : beneficiariosDelTitular) {
				clavesSistema.add(beneficiario.Clave_Sistema_Beneficiario_2__c);
			}
		}// Es solo beneficiario
		else if (tieneBeneficiarios){
            system.debug(clientes[0].Beneficiarios__r);
			for (Beneficiario__c beneficiario : clientes[0].Beneficiarios__r) {
            	clavesSistema.add(beneficiario.Clave_Sistema_Beneficiario_2__c);
			}
		}

		//if (clientes[0].Contratos__r != null && !clientes[0].Contratos__r.isEmpty()) {
			//for (Contrato__c contrato : clientes[0].Contratos__r) {
				//clavesSistema.add(contrato.Clave_Sistema_Contrato__c);
			//}
		//}
		//else if (clientes[0].Beneficiarios__r != null && !clientes[0].Beneficiarios__r.isEmpty()) {
			//for (Beneficiario__c beneficiario : clientes[0].Beneficiarios__r) {
				//clavesSistema.add(beneficiario.Clave_Sistema_Beneficiario_2__c);
			//}
		//}

		return clavesSistema;
	}
}