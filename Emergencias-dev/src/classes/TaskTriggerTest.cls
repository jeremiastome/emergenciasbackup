@IsTest
public class TaskTriggerTest {
    private static testMethod void whenDueDateChangesTheActvityDateHasToChangeToo(){
        aTask.fecha_de_vencimiento__c = System.DateTime.now().addDays(1);
        Update aTask;
        Task updatedTask = [SELECT Id, fecha_de_vencimiento__c, activityDate FROM Task where ID = :aTask.Id];
        Date expectedDate = date.newInstance(
            updatedTask.Fecha_de_Vencimiento__c.year(),
            updatedTask.Fecha_de_Vencimiento__c.month(), 
            updatedTask.Fecha_de_Vencimiento__c.day()
        );
        System.assertEquals(expectedDate, updatedTask.ActivityDate);
    }
    
    //==========================================================================
	static Task aTask;
    static{
        aTask = Build.aTask().withDueDate(System.DateTime.now()).build();
        insert aTask;
    }

    
}