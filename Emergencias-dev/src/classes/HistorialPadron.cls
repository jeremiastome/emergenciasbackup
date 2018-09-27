public class HistorialPadron {
	public string producto;
	public string provincia;
	public Date fechaDePadron;
	public Boolean esDeEliminacion;
	public Cobertura_de_Beneficiario__c coverage;

	public HistorialPadron(string producto, string provincia,
		Date fechaDePadron,
		Cobertura_de_Beneficiario__c coverage,
		Boolean esDeEliminacion) {
		this.producto = producto;
		this.provincia = provincia;
		this.fechaDePadron = fechaDePadron;
		this.coverage = coverage;
		this.esDeEliminacion = esDeEliminacion;
	}
}