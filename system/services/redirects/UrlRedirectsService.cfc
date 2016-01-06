/**
 * @singleton true
 *
 */
component {

// CONSTRUCTOR
	/**
	 * @ruleDao.inject      presidecms:object:url_redirect_rule
	 * @linksService.inject linksService
	 */
	public any function init( required any ruleDao, required any linksService ) {
		_setRuleDao( arguments.ruleDao );
		_setLinksService( arguments.linksService );

		return this;
	}

// PUBLIC API METHODS
	public void function redirectOnMatch( required string path, required string fullUrl ) {
		var ruleDao = _getRuleDao();
		var dbAdapter = ruleDao.getDbAdapter();
		var match = _getRuleDao().selectData(
			  selectFields = [ "redirect_type", "redirect_to_link" ]
			, filter       = "( exact_match_only = 1 and source_url_pattern = :source_url_pattern ) or ( exact_match_only = 0 and :source_url_pattern like Concat( source_url_pattern, '%' ) )"
			, filterParams = { source_url_pattern = arguments.path }
			, orderBy      = "#dbAdapter.getLengthFunctionSql( 'source_url_pattern' )# desc"
			, maxRows      = "1"
		);

		if ( match.recordCount ) {
			var linkUrl = _getLinksService().getLinkUrl( match.redirect_to_link );

			if ( Len( Trim( linkUrl ) ) && linkUrl != arguments.fullUrl ) {
				var statusCode = ( match.redirect_type == "302" ? 302 : 301 );

				location addtoken=false url=linkUrl statusCode=statusCode;
			}
		}
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getRuleDao() {
		return _ruleDao;
	}
	private void function _setRuleDao( required any ruleDao ) {
		_ruleDao = arguments.ruleDao;
	}

	private any function _getLinksService() {
		return _linksService;
	}
	private void function _setLinksService( required any linksService ) {
		_linksService = arguments.linksService;
	}
}