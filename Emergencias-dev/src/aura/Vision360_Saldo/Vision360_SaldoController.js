({
	init : function(comp) {
        var saldo = comp.get("v.saldo");
        console.log(saldo.substring(14,saldo.length));
        try {
            var saldoDecimal = parseFloat(saldo.substring(14,saldo.length));
            if (saldoDecimal>0) {
                comp.set("v.classname", "red");
                
            } else if (saldoDecimal<0) {
                comp.set("v.classname", "green");
            }
        } catch (ex) {	
			comp.set("v.classname", "red");
        }
        
        
	}
})