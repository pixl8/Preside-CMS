component output=false {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";

		return renderContent( renderer="datetime", data=data, context="relative" );
	}

}