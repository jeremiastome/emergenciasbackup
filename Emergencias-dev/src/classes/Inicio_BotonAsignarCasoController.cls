public class Inicio_BotonAsignarCasoController {
	@AuraEnabled
	public static Case getNextCase(String queueName, String reason, boolean allowMultipleCases) {
		List<Case> cases = [
			SELECT Id, OwnerId
			FROM Case
			WHERE OwnerId = :UserInfo.getUserId()
				AND Reason = :reason
				AND Status != 'Cerrado'
			ORDER BY LastModifiedDate ASC
			LIMIT 1
		];
		if(allowMultipleCases || cases.size() == 0) {
			Group theQueue = [
				SELECT Id
				FROM Group
				WHERE Name = :queueName
			];
			cases = [
				SELECT Id, OwnerId
				FROM Case
				WHERE OwnerId = :theQueue.Id
					AND Reason = :reason
					AND Status != 'Cerrado'
				ORDER BY LastModifiedDate ASC
				LIMIT 1
			];
            
			if(cases.size() != 0) {
				Case result = cases[0];
				result.OwnerId = UserInfo.getUserId();
				update result;
				
				return result;
			}
			else {
				return null;
			}
		}
		else {
			return cases[0];
		}
	}
}