component {

	public string function default( event, rc, prc, args={} ){
		var content = HtmlEditFormat( args.data ?: "" );

		content = ReReplace( content, "\n", "<br>", "all" );

		return content;
	}

}