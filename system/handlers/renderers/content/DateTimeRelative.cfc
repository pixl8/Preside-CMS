component output=false {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";

		return '<abbr title="' & renderContent( renderer="datetime", data=data ) & '">' & renderContent( renderer="datetime", data=data, context="relative" ) & "</abbr>";
	}

}