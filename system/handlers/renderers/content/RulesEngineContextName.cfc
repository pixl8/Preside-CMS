component {

	private string function default( event, rc, prc, args={} ){
		var contextId    = args.data ?: "";
		var contextLabel = translateResource( uri="rules.contexts:#contextId#.title", defaultValue="" );
		var contextIcon  = translateResource( uri="rules.contexts:#contextId#.iconClass", defaultValue="" );

		return '<i class="fa fa-fw #contextIcon#"></i> ' & contextLabel;
	}

}