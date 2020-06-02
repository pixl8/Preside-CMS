component {
	property name="formBuilderRenderingService" inject="formBuilderRenderingService";

	public string function index( event, rc, prc, args={} ) {
		var layouts = formBuilderRenderingService.listFormFieldLayouts(
			itemType = ( args.itemType ?: ( rc.itemType ?: "" ) )
		);

		if ( !layouts.len() ) {
			return "";
		}

		args.values = [];
		args.labels = [];

		for( var layout in layouts ){
			args.values.append( layout.id );
			args.labels.append( layout.title );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}