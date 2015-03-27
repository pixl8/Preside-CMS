component output=false {

// CONSTRUCTOR
	/**
	 * @coldboxController.inject coldbox
	 * @linkDao.inject           presidecms:object:link
	 */
	public any function init( required any coldboxController, required any linkDao ) output=false {
		_setColdboxController( arguments.coldboxController );
		_setLinkDao( arguments.linkDao );

		return this;
	}

// PUBLIC API METHODS
	public string function getLinkUrl( required string linkId ) output=false {
		var link = _getLinkDao().selectData( id=arguments.linkId );

		if ( !link.recordCount ) {
			return "";
		}

		switch( link.type ){
			case "email"        : return _buildEmailHref       ( link ); break;
			case "url"          : return _buildUrlHref         ( link ); break;
			case "sitetreelink" : return _buildSitetreelinkHref( link ); break;
			case "asset"        : return _buildAssetlinkHref   ( link ); break;
		}

		return "";
	}

	public string function emailAntiSpam( required string emailAddress ) {
		var antiSpam = "";

		for ( var i=1; i lte Len( arguments.emailAddress ); i=i+1 ) {
			antiSpam = antiSpam & "&##" & Asc( Mid( arguments.emailAddress, i, 1 ) ) & ";";
		}

		return antiSpam;
	}

// PRIVATE HELPERS
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
		return emailAntiSpam( plainHref );
	}

	private string function _buildUrlHref( required query link ) output=false {
		var protocol = Len( Trim( link.external_protocol ) ) ? link.external_protocol : "http://";
		var address  = ReReplace( link.external_address, "$(https?|ftp|news)\://", "" );

		return protocol & address;
	}

	private string function _buildSitetreelinkHref( required query link ) output=false {
		return _getRequestContext().buildLink( page=link.page );
	}

	private string function _buildAssetlinkHref( required query link ) output=false {
		return _getRequestContext().buildLink( assetId=link.asset );
	}

	private any function _getRequestContext() output=false {
		return _getColdboxController().getRequestService().getContext();
	}

// GETTERS AND SETTERS
	private any function _getColdboxController() output=false {
		return _coldboxController;
	}
	private void function _setColdboxController( required any coldboxController ) output=false {
		_coldboxController = arguments.coldboxController;
	}

	private any function _getLinkDao() output=false {
		return _linkDao;
	}
	private void function _setLinkDao( required any linkDao ) output=false {
		_linkDao = arguments.linkDao;
	}
}