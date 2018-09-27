@isTest class Cuenta_AutosetCUITControllerTest {
    
	static void AssertAccountCUITWithDocumentNumberAndSex(String expectedCUIT, string document_number, string sex)
	{
		Account anAccount = Build.anAccount().withDocumentNumber(document_number).build();
		anAccount.Genero__c = sex;
		insert anAccount;	
		string response = Cuenta_AutosetCUITController.AutosetCUITToAcc(anAccount.Id);		
		anAccount = [select CUIL_CUIT__c from account where id = :anAccount.id];	

		System.assertEquals('',response);
		System.assertEquals(expectedCUIT, anAccount.CUIL_CUIT__c);	
	}

	static void AssertAccountReturnErrorWithDocumentNumberAndSex(string document_number, string sex)
	{
		Account anAccount = Build.anAccount().withDocumentNumber(document_number).build();
		anAccount.Genero__c = sex;
		insert anAccount;	
		System.assertNotEquals('',Cuenta_AutosetCUITController.AutosetCUITToAcc(anAccount.Id));
	}


    @isTest static void TestItAssignRightCuits()
    {   
		AssertAccountCUITWithDocumentNumberAndSex('27123412341', '12341234', 'Femenino');
		AssertAccountCUITWithDocumentNumberAndSex('23123412214', '12341221', 'Femenino');
		AssertAccountCUITWithDocumentNumberAndSex('20123412223', '12341222', 'Masculino');
		AssertAccountCUITWithDocumentNumberAndSex('20123411030', '12341103', 'Masculino');
		AssertAccountCUITWithDocumentNumberAndSex('23123411099', '12341109', 'Masculino');			
    }

        
	@isTest static void TestItReturnErrorWhenDocumentOrSexAreBadFormed()
	{		
		AssertAccountReturnErrorWithDocumentNumberAndSex('','Femenino');
		AssertAccountReturnErrorWithDocumentNumberAndSex('12341','Femenino');
		AssertAccountReturnErrorWithDocumentNumberAndSex('54131234123','Masculino');
		AssertAccountReturnErrorWithDocumentNumberAndSex('23123411099','Masculino');
		AssertAccountReturnErrorWithDocumentNumberAndSex(null,'Masculino');		
		AssertAccountReturnErrorWithDocumentNumberAndSex(null,null);
	}

    @isTest static void TestItReturnErrorIfExistOtherAccountWithSameCUIT()
    {        
		Account anAccount = Build.anAccount().withCUILCUIT('20123411030').build();
		insert anAccount;
		AssertAccountReturnErrorWithDocumentNumberAndSex('12341103', 'Masculino');
    }
    
}