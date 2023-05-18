component {

	private string function default( event, rc, prc, args={}, context="" ) {
		var data = args.data;

		var iconClass = translateResource( uri="formControls.iconPicker:#data#.iconClass", defaultValue="" );

		return '<i class="fa #iconClass#"></i>';
	}

}