component output=false {

	property name="linkDao" inject="presidecms:object:link";
	property name="pageDao" inject="presidecms:object:page";


// VIEWLETS
	private string function default( event, rc, prc, args={} ) {
		var link = linkDao.selectData( id=args.id ?: "" );

		if ( !link.recordCount ) {
			return "<!-- link not found -->";
		}

		switch( link.type ){
			case "email"        : args.href = _buildEmailHref       ( link, event ); break;
			case "url"          : args.href = _buildUrlHref         ( link, event ); break;
			case "sitetreelink" : args.href = _buildSitetreelinkHref( link, event ); break;
			case "asset"        : args.href = _buildAssetlinkHref   ( link, event ); break;
		}

		args.title = args.title ?: Trim( link.title );

		if ( !Len( Trim( args.body ?: "" ) ) ) {
			if ( Len( Trim( link.image ) ) ) {
				args.body = renderAsset( assetId = link.image );
			} elseif ( Len( Trim( link.text ) ) ) {
				args.body = Trim( link.text );
			} elseif ( link.type == "email" ) {
				args.body = _emailAntiSpam( link.email_address );
			} elseif ( link.type == "sitetreelink" ) {
				var page = pageDao.selectData( id=link.page, selectFields=[ "title" ] );
				args.body = page.title;
			} elseif ( link.type == "url" ) {
				args.body = args.href;
			} else {
				args.body = args.title;
			}
		}

		args.target = args.target ?: link.target;

		return renderView( view=( args.view ?: "/renderers/link/default" ), args=args );
	}

// PRVATE HELPERS
	private string function _buildEmailHref( required query link ) output=false {
		var plainHref = "mailto:#link.email_address#";
		var delim     = "?";

		if ( Len( Trim( link.email_subject ) ) ) {
			plainHref &= delim & "subject=" & UrlEncodedFormat( link.email_subject );
			delim     = "&";
		}
		if ( Len( Trim( link.email_body ) ) ) {
			plainHref &= delim & "body=" & UrlEncodedFormat( link.email_body );

		}
		return _emailAntiSpam( plainHref );
	}

	private string function _buildUrlHref( required query link ) output=false {
		var protocol = Len( Trim( link.external_protocol ) ) ? link.external_protocol : "http://";
		var address  = ReReplace( link.external_address, "$(https?|ftp|news)\://", "" );

		return protocol & address;
	}

	private string function _buildSitetreelinkHref( required query link, required any event ) output=false {
		return event.buildLink( page=link.page );
	}

	private string function _buildAssetlinkHref( required query link, required any event ) output=false {
		return event.buildLink( assetId=link.asset );
	}

	private string function _emailAntiSpam( required string emailAddress ) {
	    var antiSpam = "";

	    for ( var i=1; i lte Len( arguments.emailAddress ); i=i+1 ) {
	        antiSpam = antiSpam & "&##" & Asc( Mid( arguments.emailAddress, i, 1 ) ) & ";";
	    }

	    return antiSpam;
	}


}