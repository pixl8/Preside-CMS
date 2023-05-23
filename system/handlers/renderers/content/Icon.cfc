component {

	private string function default( event, rc, prc, args={}, context="" ) {
		var data = args.data ?: "";

		return '<i class="fa fa-#data#"></i>';
	}

}