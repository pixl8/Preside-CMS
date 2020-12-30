component {

	public string function index( event, rc, prc, args={} ) {
		arguments.args.labels = [ "" ];
		arguments.args.values = [ "" ];

		var forms = getPresideObject('formbuilder_form').selectData( filter={ active=1 } );

		for ( var aForm in forms ) {
			arguments.args.labels.append( aForm.name );
			arguments.args.values.append( aForm.id );
		}

		return renderView( view="formcontrols/select/index", args=arguments.args );
	}

}