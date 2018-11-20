component {

	property name="userDao" inject="presidecms:object:security_user";

	private string function default( event, rc, prc, args={} ){
		var link = args.data ?: "";
		var uuidPattern = "[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{16}";

		if ( isFeatureEnabled( "emailLinkShortener" ) && ReFindNoCase( uuidPattern, link ) ) {
			var linkRecord = getModel( dsl="presidecms:object:email_template_shortened_link" ).selectData( id=link );

			if ( linkRecord.recordCount ) {
				var linkText = "";
				if ( Len( linkRecord.title & linkRecord.body ) ) {
					linkText = ( Len( linkRecord.title ) ? linkRecord.title : linkRecord.body );
					if ( Trim( linkText ) != linkRecord.href ) {
						linkText &= " (#linkRecord.href#)";
					}
				} else {
					linkText = linkRecord.href;
				}

				return '<a href="#linkRecord.href#" title="#linkRecord.href#">#abbreviate( linkText, 75 )#</a>';
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
			var linkRecord = getModel( dsl="presidecms:object:email_template_shortened_link" ).selectData( id=link );

			if ( linkRecord.recordCount ) {
				var linkText = "";
				if ( Len( linkRecord.title & linkRecord.body ) ) {
					linkText = ( Len( linkRecord.title ) ? linkRecord.title : linkRecord.body );
					if ( Trim( linkText ) != linkRecord.href ) {
						linkText &= " (#linkRecord.href#)";
					}
				} else {
					linkText = linkRecord.href;
				}

				return linkText;
			}
		}

		return link
	}

}