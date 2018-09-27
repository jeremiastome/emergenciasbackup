global class BatchRentabilidadCliente implements Database.Batchable<sObject>,
                                                Database.AllowsCallouts,
                                                Database.Stateful {
  
  private List<String> Errores {get; set;}
  private Integer Exitos {get; set;}

  global BatchRentabilidadCliente() {
    Errores = new List<String>();
    Exitos = 0;
  }

  global Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(
      'SELECT Id, '+
        '(SELECT Clave_Sistema_Contrato__c '+
        'FROM Contratos__r '+
        'WHERE Estado__c = \'Activo\' OR Estado__c = \'Baja\') '+
      'FROM Account '+
      'WHERE Id IN (SELECT Cliente__c FROM Contrato__c WHERE Estado__c = \'Activo\' OR Estado__c = \'Baja\')'
    );
  }

  global void execute(Database.BatchableContext context, List<Account> scope) {
    
    List<Account> clientesAActualizar = new List<Account>();

    for (Account cliente : scope) {
      
      String[] clavesSistema = new String[] {};

      for (Contrato__c contrato : cliente.Contratos__r) {
        clavesSistema.add(contrato.Clave_Sistema_Contrato__c);
      }

      RentabilidadServiceList indice = WSEmergencias.getRentabilidadServiceList(clavesSistema);
      
      if (String.isBlank(indice.mensaje)) {
        cliente.Valor_de_rentabilidad__c = indice.Indicador;
		cliente.Saltear_envio__c = 2;//Skip sending the account's update to SAP
        clientesAActualizar.add(cliente);
      }
    }

    Database.SaveResult[] resultadoUpdate = Database.update(clientesAActualizar, false);

    for (integer i=0; i<clientesAActualizar.size(); i++) {
            
      if (!resultadoUpdate[i].isSuccess()) {
                
        // Compruebo errores y los agrego a la lista.
        String msgError = 'Cuenta: Id '+clientesAActualizar.get(i).Id+' - Error: ';
                       
        for(Database.Error err: resultadoUpdate[i].getErrors()){
            msgError += err.getmessage() + ', ';
        }

        msgError = msgError.removeEnd(',');
        Errores.add(msgError);

      } else {
        Exitos++;
      }
    }
  }
  
  global void finish(Database.BatchableContext BC) {
  
    // Envio por correo el resultado a la persona que lo inicio.
    AsyncApexJob job = [
      SELECT Id, CreatedBy.Email, Status,
        NumberOfErrors, JobItemsProcessed, TotalJobItems
      FROM AsyncApexJob
      WHERE Id = :BC.getJobId()
    ];

    String[] lineas = new String[]{};
    lineas.add('Cuentas procesadas: '+ (Exitos + Errores.size()) +' - Exitos: '+Exitos+' - Errores: '+Errores.size());
    lineas.add('Procesados '+job.TotalJobItems+' lotes, con '+job.NumberOfErrors+' errores.');
    lineas.addAll(Errores);

    if (!Test.isRunningTest()) Utils.enviarCorreoLog('BatchRentabilidadCliente '+job.Status, lineas, new String[] { job.CreatedBy.Email });
  }
}