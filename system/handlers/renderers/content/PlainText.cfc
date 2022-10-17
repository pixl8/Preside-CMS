component {

	public string function default( event, rc, prc, args={} ){
		var content = HtmlEditFormat( args.data ?: "" );

		content = ReReplace( content, "\n", "<br>", "all" );

		return content;
	}

	public string function admindatatable( event, rc, prc, args={} ){
		var content = HtmlEditFormat( args.data ?: "" );

		content = ReReplace( content, "\n", "<br>", "all" );


		var abbreviated = abbreviate( content, 50 );

		if ( content != abbreviated ) {
			content = '<span title="#HtmlEditFormat( content )#">#abbreviated#</span>';
		}


		return content;
	}

}