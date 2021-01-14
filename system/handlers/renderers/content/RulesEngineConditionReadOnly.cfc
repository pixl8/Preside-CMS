component {

	private string function default( event, rc, prc, args={} ){
		args.expressions  = args.data ?: "";
		args.ruleContext  = args.ruleContext  ?: "";
		args.filterObject = args.filterObject ?: "";

		event.include( "/css/admin/specific/rulesengine/readyOnlyExpressions/" );

		if ( Len( Trim( args.expressions ) ) ) {
			try {
				args.expressions = DeSerializeJson( args.expressions )
			} catch( any e ) {
				args.expressions = [];
			}
		} else {
			args.expressions = [];
		}

		return renderView( view="/renderers/content/rulesEngineConditionReadOnly/default", args=args );
	}

}