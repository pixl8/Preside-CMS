component output=false {

	property name="assetManagerService"  inject="AssetManagerService";

	public string function index( event, rc, prc, args={} ) output=false {

		var derivatives   = assetManagerService.listEditorDerivatives();
		args.labels       = [ translateResource( "derivatives:none.title" ) ];
		args.values       = [ "none" ];
		args.extraClasses = "derivative-select-option";

		if ( !derivatives.len() ) {
		    return "";
		}

		for( var derivative in derivatives ) {
		    args.values.append( derivative );
			args.labels.append( translateResource( uri="derivatives:#derivative#.title", defaultValue="derivatives:#derivative#.title" ) );
		}

		return renderView( view="formcontrols/select/index", args=args );

	}
}