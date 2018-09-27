public class BeneficiarioTriggerHelper {
	public static void createUniqueNumbers(List<Beneficiario__c> recipients) {
		Set<Id> holderIds = new Set<Id>();
		for(Beneficiario__c r : recipients) {
			holderIds.add(r.Titular__c);
		}
		
		Map<Id, Titular__c> holdersById = new Map<Id, Titular__c> ([
			SELECT Id, Numero_de_Titular__c, Ult_Numero_de_beneficiario__c,
				(SELECT Id FROM Beneficiarios__r)
			FROM Titular__c
			WHERE Id IN :holderIds
		]);
		
		for(Beneficiario__c r : recipients) {
			integer lastNumber;
			
			Titular__c holder = holdersById.get(r.Titular__c);
			if(holder.Ult_Numero_de_beneficiario__c == null) {
				holder.Ult_Numero_de_beneficiario__c = '0';
			}
			
			lastNumber = (
				Integer.valueOf(holder.Ult_Numero_de_beneficiario__c) < holder.Beneficiarios__r.size() ?
					holder.Beneficiarios__r.size() :
					Integer.valueOf(holder.Ult_Numero_de_beneficiario__c)
			);
			
			holder.Ult_Numero_de_beneficiario__c = ('00' + String.ValueOf(lastNumber + 1)).right(3);
			r.N_mero_nico_de_Beneficiario__c = holder.Numero_de_Titular__c + '/' + holder.Ult_Numero_de_beneficiario__c;
		}
		
		update holdersById.values();
	}

	/*public static void crearPedidosDeEmbozos(Map<Id, Beneficiario__c> beneficiarios) {
		List<Pedido_de_Embozado__c> pedidos = new List<Pedido_de_Embozado__c>();
		
		Configuracion_embozados__c config = Configuracion_embozados__c.getOrgDefaults();
		Integer proxNumero = (config.Ultimo_numero_credencial__c != null) ? config.Ultimo_numero_credencial__c.intValue() : 1;
		
		if (config == null) {
			return;
		}
		
		// Busco los beneficiarios que tengan al menos una cobertura que requiera credencial
		for (AggregateResult ag : [
			SELECT COUNT(Id) cant, Beneficiario__c idBeneficiario, MAX(Cobertura__r.Nombre_de_Producto__c) nombrePlan
			FROM Cobertura_de_Beneficiario__c
			WHERE Beneficiario__c IN :beneficiarios.keySet()
				AND Requiere_Credencial__c = true
			GROUP BY Beneficiario__c
		]) {
			
			proxNumero++;
			
			Beneficiario__c beneficiario = beneficiarios.get((Id) ag.get('idBeneficiario'));
			String nombrePlan = (String) ag.get('nombrePlan');
			
			//pedidos.add( obtenerPedidoDeEmbozado(beneficiario, proxNumero, nombrePlan));
		}
		
		//insert pedidos;
		
		config.Ultimo_numero_credencial__c = proxNumero;
		upsert config;
	}
	
	public static Pedido_de_Embozado__c obtenerPedidoDeEmbozado(Beneficiario__c beneficiario, Integer num, String nombrePlan) {
		return (new EmbozadoBuilder(beneficiario, num, nombrePlan)).obtenerPedido();
	}*/
}