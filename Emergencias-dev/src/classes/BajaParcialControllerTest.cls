@isTest
public class BajaParcialControllerTest {
    public static testMethod void placeHolderTest(){
        BajaParcialController cont = new BajaParcialController();
        cont.titularBuscar = '';
        cont.beneficiarioBuscar = '';
        cont.bajaAllTitulares();
        cont.bajaAllBeneficiarios();
        cont.cancelBajaAllTitulares();
        cont.cancelBajaAllBeneficiarios();
    }
}