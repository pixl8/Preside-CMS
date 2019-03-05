component {

// CONSTRUCTOR
	/**
	 * @coldboxController.inject coldbox
	 * @linkDao.inject           presidecms:object:link
	 */
	public any function init( required any coldboxController, required any linkDao ) {
		_setColdboxController( arguments.coldboxController );
		_setLinkDao( arguments.linkDao );

		return this;
	}

// PUBLIC API METHODS
	public string function getLinkUrl( required string linkId ) {
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

	public string function emailAntiSpam( required string emailAddress, boolean bypassAntiSpam=false ) {
		var antiSpam = "";

		if( arguments.bypassAntiSpam ){
			return arguments.emailAddress;
		}

		for ( var i=1; i lte Len( arguments.emailAddress ); i=i+1 ) {
			antiSpam = antiSpam & "&##" & Asc( Mid( arguments.emailAddress, i, 1 ) ) & ";";
		}

		return antiSpam;
	}

// PRIVATE HELPERS
	private string function _buildEmailHref( required query link ) {
		var plainHref      = "mailto:#link.email_address#";
		var delim          = "?";
		var bypassAntiSpam = IsBoolean( arguments.link.email_anti_spam ?: "" ) && arguments.link.email_anti_spam;

		if ( Len( Trim( link.email_subject ) ) ) {
			plainHref &= delim & "subject=" & UrlEncodedFormat( link.email_subject );
			delim     = "&";
		}
		if ( Len( Trim( link.email_body ) ) ) {
			plainHref &= delim & "body=" & UrlEncodedFormat( link.email_body );

		}
		return emailAntiSpam( plainHref, bypassAntiSpam );
	}

	private string function _buildUrlHref( required query link ) {
		var protocol = Len( Trim( link.external_protocol ) ) ? link.external_protocol : "http://";
		var address  = ReReplace( link.external_address, "^[a-z]\://", "" );

		return protocol & address;
	}

	private string function _buildSitetreelinkHref( required query link ) {
		var anchor = len( link.page_anchor ?: "" ) ? "##" & link.page_anchor : "";
		return _getRequestContext().buildLink( page=link.page ) & anchor;
	}

	private string function _buildAssetlinkHref( required query link ) {
		return _getRequestContext().buildLink( assetId=link.asset );
	}

	private any function _getRequestContext() {
		return _getColdboxController().getRequestService().getContext();
	}

// GETTERS AND SETTERS
	private any function _getColdboxController() {
		return _coldboxController;
	}
	private void function _setColdboxController( required any coldboxController ) {
		_coldboxController = arguments.coldboxController;
	}

	private any function _getLinkDao() {
		return _linkDao;
	}
	private void function _setLinkDao( required any linkDao ) {
		_linkDao = arguments.linkDao;
	}
}