component {

	property name="presideObjectService"   inject="presideObjectService";
	property name="contentRendererService" inject="contentRendererService";

	public string function index( event, rc, prc, args={} ) {
		var sourceObject = args.sourceObject ?: "";

		if( sourceObject.len() ) {
			var properties = presideObjectService.getObjectProperties( sourceObject );
			var prop       = properties[ args.name ] ?: {};

			args.renderer  = args.renderer ?: contentRendererService.getRendererForField( prop );
		}

		if ( !contentRendererService.rendererExists( args.renderer ?: "" ) ) {
			args.renderer = "";
		}

		return renderView( view="formcontrols/readOnly/index", args=args );
	}

}