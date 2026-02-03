/**
 * @feature presideForms and formbuilder
 */
component {

	public string function index( event, rc, prc, args={} ) {
		args.labels = [ "" ];
		args.values = [ "" ];

		var forms = getPresideObject( "formbuilder_form" ).selectData( filter={ active=true } );

		for ( var aForm in forms ) {
			args.labels.append( aForm.name );
			args.values.append( aForm.id );
		}

		return renderView( view="/formcontrols/select/index", args=args );
	}

}
