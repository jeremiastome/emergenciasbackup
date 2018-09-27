@isTest
private class Opp_ValidarAdvertenciasControllerTest {
	//===============================================
	// Warnings on Default
	private static testMethod void whenValidating_IfTheOpportunitysAccountIsDefaulting_AWarningShouldBeGenerated() {
		anAccount.Morosidad_SAP__c = '30';
		update anAccount;
		
		List<Advertencia__c> warnings = Opp_ValidarAdvertenciasController.validateWarnings(anOpportunity.Id);
		
		System.assertEquals(1, warnings.size());
		System.assertEquals('Morosidad', warnings[0].Clase_de_advertencia__c);
		System.assertEquals(Label.Advertencia_detalle_morosidad, warnings[0].Detalle__c);
		System.assertNotEquals(null, warnings[0].Id);
	}
	
	private static testMethod void whenValidating_ifTheOpportunityHadADefaultingAccountWarningAndTheAccountIsStillDefaulting_TheWarningShouldNotBeRepeated() {
		anAccount.Morosidad_SAP__c = '30';
		update anAccount;
		Advertencia__c aWarning = Build.aWarning().forOpportunity(anOpportunity)
			.withWarningTypeDefault().build();
		insert aWarning;
		
		List<Advertencia__c> warnings = Opp_ValidarAdvertenciasController.validateWarnings(anOpportunity.Id);
		
		System.assertEquals(1, warnings.size());
		System.assertEquals(aWarning.Id, warnings[0].Id);
	}
	
	private static testMethod void whenValidating_ifTheOpportunityHadADefaultingAccountWarningAndTheAccountIsNoLongerDefaulting_TheWarningShouldBeMarkedAsResolved() {
		anAccount.Morosidad_SAP__c = '';
		update anAccount;
		Advertencia__c aWarning = Build.aWarning().forOpportunity(anOpportunity)
			.withWarningTypeDefault().build();
		insert aWarning;
		
		List<Advertencia__c> warnings = Opp_ValidarAdvertenciasController.validateWarnings(anOpportunity.Id);
		
		System.assertEquals(0, warnings.size());
		
		List<Advertencia__c> warningsInDB = [
			SELECT Id, Resuelto__c
			FROM Advertencia__c
			WHERE Id = :aWarning.Id
		];
		
		System.assertEquals(1, warningsInDB.size());
		System.assertEquals(true, warningsInDB[0].Resuelto__c);
	}
	
	//===============================================
	// Warnings on Not profitable
	private static testMethod void whenValidating_IfTheOpportunitysAccountIsNotProfitable_AWarningShouldBeGenerated() {
		anAccount.Valor_de_rentabilidad__c = 'NR';
		update anAccount;
		
		List<Advertencia__c> warnings = Opp_ValidarAdvertenciasController.validateWarnings(anOpportunity.Id);
		
		System.assertEquals(1, warnings.size());
		System.assertEquals('Rentabilidad', warnings[0].Clase_de_advertencia__c);
		System.assertEquals(Label.Advertencia_detalle_rentabilidad, warnings[0].Detalle__c);
		System.assertNotEquals(null, warnings[0].Id);
	}
	
	private static testMethod void 	whenValidating_ifTheOpportunityHadANotProfitableAccountWarningAndTheAccountIsNowProfitable_TheWarningShouldBeMarkedAsResolved() {
		anAccount.Valor_de_rentabilidad__c = '';
		update anAccount;
		Advertencia__c aWarning = Build.aWarning().forOpportunity(anOpportunity)
			.withWarningTypeNotProfitable().build();
		insert aWarning;
		
		List<Advertencia__c> warnings = Opp_ValidarAdvertenciasController.validateWarnings(anOpportunity.Id);
		
		System.assertEquals(0, warnings.size());
		
		List<Advertencia__c> warningsInDB = [
			SELECT Id, Resuelto__c
			FROM Advertencia__c
			WHERE Id = :aWarning.Id
		];
		
		System.assertEquals(1, warningsInDB.size());
		System.assertEquals(true, warningsInDB[0].Resuelto__c);
	}
	
	//===============================================
	// Warnings on Conditioned access zone
	private static testMethod void whenValidating_IfTheOpportunitysAccountIsInADangerousZone_AWarningShouldBeGenerated() {
		anAccount.Zona_de_facturacion__c = aZone.Id;
		update anAccount;
		
		List<Advertencia__c> warnings = Opp_ValidarAdvertenciasController.validateWarnings(anOpportunity.Id);
		
		System.assertEquals(1, warnings.size());
		System.assertEquals('Zona de acceso condicionado', warnings[0].Clase_de_advertencia__c);
		System.assertEquals(Label.Advertencia_acceso_condicionado, warnings[0].Detalle__c);
		System.assertNotEquals(null, warnings[0].Id);
	}
	
	private static testMethod void whenValidating_ifTheOpportunityHadADangerousZoneAccountWarningAndTheAccountIsNoLongerInADangerousZone_TheWarningShouldBeMarkedAsResolved() {
		anAccount.Zona_de_facturacion__c = null;
		update anAccount;
		Advertencia__c aWarning = Build.aWarning().forOpportunity(anOpportunity)
			.withWarningTypeDangerousZone().build();
		insert aWarning;
		
		List<Advertencia__c> warnings = Opp_ValidarAdvertenciasController.validateWarnings(anOpportunity.Id);
		
		System.assertEquals(0, warnings.size());
		
		List<Advertencia__c> warningsInDB = [
			SELECT Id, Resuelto__c
			FROM Advertencia__c
			WHERE Id = :aWarning.Id
		];
		
		System.assertEquals(1, warningsInDB.size());
		System.assertEquals(true, warningsInDB[0].Resuelto__c);
	}
	//===============================================
	// Warnings on PAU
	private static testMethod void whenValidating_IfTheOpportunitysAccountIsPAU_AWarningShouldBeGenerated() {
		anAccount.Es_PAU__c = true;
        anAccount.Motivo_PAU__c = 'Some cause';
		update anAccount;
		
		List<Advertencia__c> warnings = Opp_ValidarAdvertenciasController.validateWarnings(anOpportunity.Id);
		
		System.assertEquals(1, warnings.size());
		System.assertEquals('PAU', warnings[0].Clase_de_advertencia__c);
		System.assertEquals(Label.Advertencia_PAU, warnings[0].Detalle__c);
		System.assertNotEquals(null, warnings[0].Id);
	}
	
	private static testMethod void whenValidating_IfTheOpportunitysContractHasARecipientAccountThatIsPAU_AWarningShouldBeGenerated() {
		anAccount.Es_PAU__c = false;
		update anAccount;
		Account recipientAccount = Build.anAccount().isPAU().build();
		insert recipientAccount;
		Contrato__c theContract = [
			SELECT Id
			FROM Contrato__c
			WHERE Id IN (
					SELECT Contrato__c
					FROM Opportunity
					WHERE Id = :anOpportunity.Id
				)
		];
		Titular__c aHolder = [
			SELECT Id
			FROM Titular__c
			WHERE Contrato__c = :theContract.Id
			LIMIT 1
		];
		insert Build.aRecipient().forContract(theContract).forAccount(recipientAccount).forHolder(aHolder).build();
		
		List<Advertencia__c> warnings = Opp_ValidarAdvertenciasController.validateWarnings(anOpportunity.Id);
		
		System.assertEquals(1, warnings.size());
		System.assertEquals('PAU', warnings[0].Clase_de_advertencia__c);
		System.assertEquals(Label.Advertencia_PAU, warnings[0].Detalle__c);
		System.assertNotEquals(null, warnings[0].Id);
	}
	
	private static testMethod void whenValidating_ifTheOpportunityHadAPAUAccountWarningAndThereIsNoLongerAPAUAccountRelated_TheWarningShouldBeMarkedAsResolved() {
		anAccount.Es_PAU__c = false;
		update anAccount;
		Advertencia__c aWarning = Build.aWarning().forOpportunity(anOpportunity)
			.withWarningTypePAU().build();
		insert aWarning;
		
		List<Advertencia__c> warnings = Opp_ValidarAdvertenciasController.validateWarnings(anOpportunity.Id);
		
		System.assertEquals(0, warnings.size());
		
		List<Advertencia__c> warningsInDB = [
			SELECT Id, Resuelto__c
			FROM Advertencia__c
			WHERE Id = :aWarning.Id
		];
		
		System.assertEquals(1, warningsInDB.size());
		System.assertEquals(true, warningsInDB[0].Resuelto__c);
	}
	
	
	//===============================================
	// Other
	private static testMethod void itShouldBePosibleToGetTheWarningsThatWerentSolvedForAnOpportunity() {
		List<Advertencia__c> warnings = new List<Advertencia__c> {
			Build.aWarning().forOpportunity(anOpportunity).withWarningTypeNotProfitable().build(),
			Build.aWarning().forOpportunity(anOpportunity).withWarningTypeDefault().build()
		};
		insert warnings;
		Map<Id, Advertencia__c> warningsById = new Map<Id, Advertencia__c>(warnings);
		
		List<Advertencia__c> result = Opp_ValidarAdvertenciasController.getWarnings(anOpportunity.Id);
		
		System.assertEquals(warnings.size(), result.size());
		for(Advertencia__c warning : result) {
			System.assert(warningsById.containsKey(warning.Id));
		}
	}
	
	private static testMethod void afterValidatingTheOpportunityShouldBeMarkedAsSuch() {
		Opp_ValidarAdvertenciasController.validateWarnings(anOpportunity.Id);
		
		Opportunity theOpportunityInDb = [
			SELECT Id, Advertencias_validadas__c
			FROM Opportunity
			WHERE Id = :anOpportunity.Id
		];
		
		System.assertEquals(true, theOpportunityInDb.Advertencias_validadas__c);
	}
	
	private static testMethod void itShouldBePosibleToObtainIfTheOpportunityWasPreviouslyValidated() {
		System.assertEquals(false, Opp_ValidarAdvertenciasController.wasOpportunityValidated(anOpportunity.Id));
		
		anOpportunity.Advertencias_validadas__c = true;
		update anOpportunity;
		
		System.assertEquals(true, Opp_ValidarAdvertenciasController.wasOpportunityValidated(anOpportunity.Id));
	}
	
	//==========================================================================
	static Account anAccount;
	static Opportunity anOpportunity;
	static Zona__c aZone;
	static {
		anAccount = Build.anAccount().build();
		insert anAccount;
		anOpportunity = Build.anOpportunity().forAccount(anAccount).withDischargeTypeNew().build();
		insert anOpportunity;
		aZone = Build.aZone().withTypeConditionedAccess().build();
		insert aZone;

        
	}
}