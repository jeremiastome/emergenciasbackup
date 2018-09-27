({
	preparePosition: function (pos) {
		//Prepare a position to be shown,
		// then return the total price of the position
		var totalPrice = pos.noIvaPrice + pos.priceIVA;
		pos.hasIva = pos.priceIVA != 0;
		pos.noIvaPrice = pos.noIvaPrice.toFixed(2);
		pos.priceIVA = pos.priceIVA.toFixed(2);
		pos.basePrice = pos.basePrice.toFixed(2);
		pos.totalPrice = totalPrice.toFixed(2);
		
		for (var i = 0; i < pos.surcharges.length; i++) {
			pos.surcharges[i].price = pos.surcharges[i].price.toFixed(2);
		}
		for (var i = 0; i < pos.discounts.length; i++) {
			pos.discounts[i].price = pos.discounts[i].price.toFixed(2);
		}
		
		pos.isInTransit = pos.isInTransit?"Si":"No";
		pos.showDetails = false;
		
		return totalPrice;
	}
})