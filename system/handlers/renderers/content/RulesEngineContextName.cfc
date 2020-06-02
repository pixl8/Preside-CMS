component {


	public string function default( event, rc, prc, args={} ){
		var contextId = args.data ?: "";

		return translateResource( uri="rules.contexts:#contextId#.title", defaultValue="" )
	}

}