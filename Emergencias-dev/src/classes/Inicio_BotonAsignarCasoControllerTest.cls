@isTest
private class Inicio_BotonAsignarCasoControllerTest {
	private static testMethod void itShouldBePosibleToHaveACaseAssignedFromTheSpecifiedQueue() {
		Case result = Inicio_BotonAsignarCasoController.getNextCase(theQueue.Name, aCase.Reason, false);
		
		System.assertEquals(aCase.Id, result.Id);
		System.assertEquals(UserInfo.getUserId(), result.OwnerId, false);
		
		Case theCaseInDb = [
			SELECT OwnerId
			FROM Case
			WHERE Id = :aCase.Id
		];
		
		System.assertEquals(UserInfo.getUserId(), theCaseInDb.OwnerId);
	}
	
	private static testMethod void ifTheUserAlreadyHasACaseAssignedOfTheCaseReasonAndOnlyOneCaseIsAllowed_NoNewCaseShouldBeAssigned() {
		Case anAssignedCase = Build.aCase().withOwner(myself).forAccount(anAccount).withReason(aCase.Reason).build();
		insert anAssignedCase;
		
		Case result = Inicio_BotonAsignarCasoController.getNextCase(theQueue.Name, aCase.Reason, false);
		
		System.assertEquals(anAssignedCase.Id, result.Id);
		
		Case theCaseInDb = [
			SELECT OwnerId
			FROM Case
			WHERE Id = :aCase.Id
		];
		
		System.assertEquals(theQueue.Id, theCaseInDb.OwnerId);
	}
	
	private static testMethod void ifTheUserAlreadyHasACaseAssignedOfTheCaseReasonAndMoreThanOneCaseIsAllowed_ANewCaseShouldBeAssigned() {
		Case anAssignedCase = Build.aCase().withOwner(myself).forAccount(anAccount).withReason(aCase.Reason).build();
		insert anAssignedCase;
		
		Case result = Inicio_BotonAsignarCasoController.getNextCase(theQueue.Name, aCase.Reason, true);
		
		System.assertEquals(aCase.Id, result.Id);
	}
	
	private static testMethod void ifThereAreNoCasesToAssignNoneShouldBeReturned() {
		delete aCase;
		
		Case result = Inicio_BotonAsignarCasoController.getNextCase(theQueue.Name, aCase.Reason, false);
		
		System.assertEquals(null, result);
	}
	
	private static testMethod void aClosedCaseShouldNotBeReturnedWhenSearchingForTheNextCase() {
		Case anAssignedCase = Build.aCase().withOwner(myself).forAccount(anAccount)
			.withReason(aCase.Reason).WithCloseReason('Conforme').isClosed().build();
		insert anAssignedCase;
		
		Case result = Inicio_BotonAsignarCasoController.getNextCase(theQueue.Name, aCase.Reason, false);
		
		System.assertEquals(aCase.Id, result.Id);
	}
	//==========================================================================
	static Group theQueue;
	static Case aCase;
	static Account anAccount;
	static User myself;
	
	static {
		myself = new User(Id = UserInfo.getUserId());
		System.runAs(myself) {
			//Execute in different context
			theQueue = Build.aGroup().isQueue().withName('My queue').build();
			insert theQueue;
			QueueSobject aQueueSobject = Build.aQueueSobject().forSObjectCase().forQueue(theQueue).build();
			insert aQueueSobject;
		}
		anAccount = Build.anAccount().build();
		insert anAccount;
		aCase = Build.aCase().withOwner(theQueue).forAccount(anAccount).withReason('Servicio – Operaciones').build();
		insert aCase;
	}
}