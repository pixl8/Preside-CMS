component {

	private string function default( event, rc, prc, args={} ){
		var link = args.data ?: "";
		var uuidPattern = "[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{16}";

		if ( isFeatureEnabled( "emailLinkShortener" ) && ReFindNoCase( uuidPattern, link ) ) {
			link = getModel( dsl="presidecms:object:email_template_shortened_link" ).selectData( id=link );

			if ( link.recordCount ) {
				var linkText = "";
				if ( Len( link.title & link.body ) ) {
					linkText = ( Len( link.title ) ? link.title : link.body );
					if ( Trim( linkText ) != link.href ) {
						linkText &= " (#link.href#)";
					}
				} else {
					linkText = link.href;
				}

				return '<a href="#link.href#" title="#link.href#">#abbreviate( linkText, 75 )#</a>';
			}
		}

		if ( ReFindNoCase( "^https?://", link ) ) {
			return '<a href="#link#" title="#link#">#abbreviate( link, 75 )#</a>';
		}

		return link
	}

	private string function dataExport( event, rc, prc, args={} ){
		var link = args.data ?: "";
		var uuidPattern = "[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{16}";

		if ( isFeatureEnabled( "emailLinkShortener" ) && ReFindNoCase( uuidPattern, link ) ) {
			link = getModel( dsl="presidecms:object:email_template_shortened_link" ).selectData( id=link );

			if ( link.recordCount ) {
				var linkText = "";
				if ( Len( link.title & link.body ) ) {
					linkText = ( Len( link.title ) ? link.title : link.body );
					if ( Trim( linkText ) != link.href ) {
						linkText &= " (#link.href#)";
					}
				} else {
					linkText = link.href;
				}

				return linkText;
			}
		}

		return link
	}

}