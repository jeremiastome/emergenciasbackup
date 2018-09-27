public class HistorialPadronesUtils {

	public static void registrarActualizacion(
		List<HistorialPadron> historialToSave,
		Map<Id, Decimal> anterioresValores,
		String contractId
		) {
		List<Historial_de_Padron__c> historiales = buildHistoriales(
			historialToSave, anterioresValores, contractId);

		if(!historiales.isEmpty()) {
			insert historiales;
		}
	}

	public static List<Historial_de_Padron__c> buildHistoriales(
		List<HistorialPadron> historialToSave,
		Map<Id, Decimal> anterioresValores,
		String contractId
		) {
		List<Historial_de_Padron__c> historiales = new List<Historial_de_Padron__c>();
		for(HistorialPadron historial : historialToSave) {
			Historial_de_Padron__c newHistorial = new Historial_de_Padron__c();
			newHistorial.Fecha_de_modificacion__c = DateTime.now();
			newHistorial.Contrato__c = contractId;
			newHistorial.Fecha_de_padron__c = historial.fechaDePadron;
			newHistorial.Producto__c = historial.producto;
			newHistorial.Provincia__c = historial.provincia;
			newHistorial.Tratamiento_de_IVA__c = historial.coverage.Tratamiento_de_IVA__c;
			newHistorial.Cantidad_de_capitas__c = historial.coverage.Cantidad_de_Padron__c;
			newHistorial.Clave_historial__c = contractId +'_'+
				historial.producto +'_'+
				historial.provincia +'_'+
				historial.coverage.Tratamiento_de_IVA__c;
			if(historial.esDeEliminacion) {
				newHistorial.Tipo_de_operacion__c = 'Eliminacion';
				historiales.add(newHistorial);
			}
			else {
				if(anterioresValores.containsKey(historial.coverage.id)) {
					if(anterioresValores.get(historial.coverage.id) != historial.coverage.Cantidad_de_Padron__c) {
						newHistorial.Tipo_de_operacion__c = 'Modificacion';
						historiales.add(newHistorial);
					}
				}
				else {
					newHistorial.Tipo_de_operacion__c = 'Creacion';
					historiales.add(newHistorial);
				}
			}
		}
		return historiales;
	}
}