/**
 * Provides service logic for recording user actions (auditing)
 *
 * @autodoc
 * @singleton
 * @presideService
 */
component displayName="Website user action service" {

// CONSTRUCTOR
	/**
	 * @websiteVisitorService.inject websiteVisitorService
	 * @sessionStorage.inject        sessionStorage
	 */
	public any function init(
		  required any websiteVisitorService
		, required any sessionStorage
	) {
		_setWebsiteVisitorService( arguments.websiteVisitorService );
		_setSessionStorage( arguments.sessionStorage );

		return this;
	}

// PUBLIC API
	/**
	 * Records an action for the given user
	 *
	 * @autodoc
	 * @userId.hint     ID of the user to record the action for
	 * @action.hint     ID of the action to record, e.g. 'logout'
	 * @type.hint       Type of the action to record, e.g. 'login'
	 * @identifier.hint Unique identifier to the subject of the action, e.g. a page ID for a 'pagevisit' action
	 * @detail.hint     Additional detail to record with the action, will be serialized to JSON when saved in the DB
	 */
	public string function recordAction(
		  required string action
		, required string type
		,          string userId     = ""
		,          string identifier = ""
		,          any    detail     = {}
	) {
		if ( _sessionsAreDisabled() || ( !arguments.userId.len() && _anonymousTrackingIsDisabled() ) ) {
			return "";
		}

		var data = {
			  action     = arguments.action
			, type       = arguments.type
			, detail     = SerializeJson( arguments.detail )
			, identifier = arguments.identifier
			, session_id = _getSessionId()
			, uri        = cgi.request_url
			, user_ip    = cgi.remote_addr
			, user_agent = cgi.http_user_agent
			, visitor    = _getWebsiteVisitorService().getVisitorId()
		};

		if ( Len( Trim( arguments.userId ) ) ) {
			data.user = arguments.userId;
		} else if ( !Len( Trim( data.visitor ) ) ) {
			return "";
		}

		return $getPresideObject( "website_user_action" ).insertData( data );
	}

	/**
	 * Transfers all of the current visitor's actions
	 * for this session to the given user
	 *
	 * @autodoc
	 * @userId.hint ID of the user who will take the visitor's actions
	 *
	 */
	public numeric function promoteVisitorActionsToUserActions( required string userId ) {
		var sessionId = _getSessionId();
		var visitorId = _getWebsiteVisitorService().getVisitorId();

		return $getPresideObject( "website_user_action" ).updateData(
			  filter = { "website_user_action.session_id"=sessionId, "website_user_action.visitor"=visitorId }
			, data   = { user=arguments.userId }
		);
	}

	/**
	 * Returns the date that an action was last performed
	 * by the given user / visitor
	 *
	 * @autodoc
	 * @type.hint        Type of the action
	 * @action.hint      Action ID
	 * @identifiers.hint Array of identifiers with which to filter the actions
	 * @userId.hint      ID of the user who performed the action (if blank or ommitted, the current visitor ID will be used instead)
	 */
	public string function getLastPerformedDate(
		  required string type
		, required string action
		,          string userId      = ""
		,          array  identifiers = []
	) {
		var filter = { "website_user_action.type"=arguments.type, "website_user_action.action"=arguments.action };

		if ( Len( Trim( arguments.userId ) ) ) {
			filter[ "website_user_action.user" ] = arguments.userId;
		} else {
			filter[ "website_user_action.visitor" ] = _getWebsiteVisitorService().getVisitorId();
		}

		if ( arguments.identifiers.len() ) {
			filter[ "website_user_action.identifier" ] = arguments.identifiers;
		}

		var record = $getPresideObject( "website_user_action" ).selectData(
			  filter       = filter
			, selectFields = [ "Max( website_user_action.datecreated ) as datecreated" ]
		);

		return record.datecreated ?: "";
	}

	/**
	 * Returns whether or not the given user
	 * has performed the given action. Uses
	 * the current visitor when no user supplied.
	 *
	 * @autodoc
	 * @type.hint        Type of the action
	 * @action.hint      Action ID
	 * @userId.hint      ID of the user who performed the action (if blank or ommitted, the current visitor ID will be used instead)
	 * @dateFrom.hint    Optional date from which the user has performed the action
	 * @dateTo.hint      Optional date to which the user has performed the action
	 * @identifiers.hint Array of identifiers with which to filter the actions
	 */
	public boolean function hasPerformedAction(
		  required string type
		, required string action
		,          string userId      = ""
		,          string dateFrom    = ""
		,          string dateTo      = ""
		,          array  identifiers = []
	) {
		var filter = { "website_user_action.type"=arguments.type, "website_user_action.action"=arguments.action };
		var extraFilters = [];

		if ( Len( Trim( arguments.userId ) ) ) {
			filter[ "website_user_action.user" ] = arguments.userId;
		} else {
			filter[ "website_user_action.visitor" ] = _getWebsiteVisitorService().getVisitorId();
		}

		if ( IsDate( arguments.dateFrom ) ) {
			extraFilters.append({
				  filter       = "website_user_action.datecreated >= :datefrom"
				, filterParams = { datefrom = { type="timestamp", value=arguments.dateFrom } }
			});
		}

		if ( IsDate( arguments.dateTo ) ) {
			extraFilters.append({
				  filter       = "website_user_action.datecreated <= :dateto"
				, filterParams = { dateto = { type="timestamp", value=arguments.dateTo } }
			});
		}

		if ( arguments.identifiers.len() ) {
			filter[ "website_user_action.identifier" ] = arguments.identifiers;
		}

		return $getPresideObject( "website_user_action" ).dataExists( filter=filter, extraFilters=extraFilters );
	}

	/**
	 * Returns number of times the given user
	 * has performed the given action. Uses
	 * the current visitor when no user supplied.
	 *
	 * @autodoc
	 * @type.hint        Type of the action
	 * @action.hint      Action ID
	 * @userId.hint      ID of the user who performed the action (if blank or ommitted, the current visitor ID will be used instead)
	 * @dateFrom.hint    Optional date from which the user has performed the action
	 * @dateTo.hint      Optional date to which the user has performed the action
	 * @identifiers.hint Array of identifiers with which to filter the actions
	 */
	public numeric function getActionCount(
		  required string type
		, required string action
		,          string userId      = ""
		,          string dateFrom    = ""
		,          string dateTo      = ""
		,          array  identifiers = []
	) {
		var filter = { "website_user_action.type"=arguments.type, "website_user_action.action"=arguments.action };
		var extraFilters = [];

		if ( Len( Trim( arguments.userId ) ) ) {
			filter[ "website_user_action.user" ] = arguments.userId;
		} else {
			filter[ "website_user_action.visitor" ] = _getWebsiteVisitorService().getVisitorId();
		}

		if ( IsDate( arguments.dateFrom ) ) {
			extraFilters.append({
				  filter       = "website_user_action.datecreated >= :datefrom"
				, filterParams = { datefrom = { type="timestamp", value=arguments.dateFrom } }
			});
		}
		if ( IsDate( arguments.dateTo ) ) {
			extraFilters.append({
				  filter       = "website_user_action.datecreated <= :dateto"
				, filterParams = { dateto = { type="timestamp", value=arguments.dateTo } }
			});
		}

		if ( arguments.identifiers.len() ) {
			filter[ "website_user_action.identifier" ] = arguments.identifiers;
		}

		var result = $getPresideObject( "website_user_action" ).selectData(
			  filter       = filter
			, extraFilters = extraFilters
			, selectFields = [ "Count(1) as action_count" ]
		);

		return Val( result.action_count ?: "" );
	}

	public array function getUserPerformedActionFilter(
		  required string  type
		, required string  action
		,          boolean has                = true
		,          string  datefrom           = ""
		,          string  dateto             = ""
		,          array   identifiers        = []
		,          boolean allIdentifiers     = false
		,          numeric qty
		,          string  qtyOperator        = "gt"
		,          string  filterPrefix       = ""
		,          string  parentPropertyName = ""
	) {
		if ( arguments.identifiers.len() > 1 && arguments.allIdentifiers ) {
			var filters = [];

			for( var identifier in arguments.identifiers ) {
				filters.append( getUserPerformedActionFilter( argumentCollection=arguments, identifiers=[ identifier ] ), true );
			}

			return filters;
		}

		var paramSuffix    = _getRandomFilterParamSuffix();
		var subqueryFilter = "actions.action = :action#paramSuffix# and actions.type = :type#paramSuffix#";
		var subqueryAlias  = "actioncount" & paramSuffix;
		var overallFilter  = "";
		var params         = {
			  "action#paramSuffix#" = { type="cf_sql_varchar", value=arguments.action }
			, "type#paramSuffix#"   = { type="cf_sql_varchar", value=arguments.type   }
		};

		if ( IsDate( arguments.datefrom ) ) {
			subqueryFilter &= " and actions.datecreated >= :datefrom#paramSuffix#";
			params[ "datefrom#paramSuffix#" ] = { type="cf_sql_timestamp", value=arguments.datefrom };
		}
		if ( IsDate( arguments.dateto ) ) {
			subqueryFilter &= " and actions.datecreated <= :dateto#paramSuffix#";
			params[ "dateto#paramSuffix#" ] = { type="cf_sql_timestamp", value=arguments.dateto };
		}
		if ( arguments.identifiers.len() ) {
			subqueryFilter &= " and actions.identifier in ( :identifiers#paramSuffix# )";
			params[ "identifiers#paramSuffix#" ] = { type="cf_sql_varchar", value=arguments.identifiers.toList(), list=true };
		}

		var subquery = $getPresideObject( "website_user" ).selectData(
			  selectFields        = [ "Count( actions.id ) as action_count", "website_user.id" ]
			, filter              = subqueryFilter
			, groupBy             = "website_user.id"
			, getSqlAndParamsOnly = true
			, forceJoins          = "inner"
		);

		if ( arguments.has ) {
			if ( StructKeyExists( arguments, "qty" ) ) {
				overallFilter = "#subqueryAlias#.action_count ${operator} :qty#paramSuffix#";
				params[ "qty#paramSuffix#" ] = { type="cf_sql_integer", value=arguments.qty };

				switch ( arguments.qtyOperator ) {
					case "eq":
						overallFilter = overallFilter.replace( "${operator}", "=" );
					break;
					case "neq":
						overallFilter = overallFilter.replace( "${operator}", "!=" );
					break;
					case "gt":
						overallFilter = overallFilter.replace( "${operator}", ">" );
					break;
					case "gte":
						overallFilter = overallFilter.replace( "${operator}", ">=" );
					break;
					case "lt":
						overallFilter = overallFilter.replace( "${operator}", "<" );
					break;
					case "lte":
						overallFilter = overallFilter.replace( "${operator}", "<=" );
					break;
					default:
						overallFilter = overallFilter.replace( "${operator}", ">" );
				}

			} else {
				overallFilter = "#subqueryAlias#.action_count > 0";
			}
		} else {
			overallFilter = "( #subqueryAlias#.action_count is null or #subqueryAlias#.action_count = 0 )";
		}

		return [ { filter=overallFilter, filterParams=params, extraJoins=[ {
			  type           = "left"
			, subQuery       = subquery.sql
			, subQueryAlias  = subqueryAlias
			, subQueryColumn = "id"
			, joinToTable    = arguments.filterPrefix.len() ? arguments.filterPrefix : ( arguments.parentPropertyName.len() ? arguments.parentPropertyName : "website_user" )
			, joinToColumn   = "id"
		} ] } ];
	}

	public array function getUserLastPerformedActionFilter(
		  required string  type
		, required string  action
		,          string  dateFrom           = ""
		,          string  dateTo             = ""
		,          string  identifier         = ""
		,          string  filterPrefix       = ""
		,          string  parentPropertyName = ""
	) {
		var paramSuffix    = _getRandomFilterParamSuffix();
		var subqueryFilter = "actions.action = :action#paramSuffix# and actions.type = :type#paramSuffix#";
		var subqueryAlias  = "lastPerformed" & paramSuffix;
		var overallFilter  = "";
		var delimiter      = "";
		var params         = {
			  "action#paramSuffix#" = { type="cf_sql_varchar", value=arguments.action }
			, "type#paramSuffix#"   = { type="cf_sql_varchar", value=arguments.type   }
		};

		if ( IsDate( arguments.datefrom ) ) {
			overallFilter = "#subqueryAlias#.action_date >= :datefrom#paramSuffix#";
			params[ "datefrom#paramSuffix#" ] = { type="cf_sql_timestamp", value=arguments.datefrom };
			delimiter = " and ";
		}
		if ( IsDate( arguments.dateto ) ) {
			overallFilter &= delimiter & "#subqueryAlias#.action_date <= :dateto#paramSuffix#";
			params[ "dateto#paramSuffix#" ] = { type="cf_sql_timestamp", value=arguments.dateto };
		}
		if ( arguments.identifier.len() ) {
			subqueryFilter &= " and actions.identifier = :identifier#paramSuffix#";
			params[ "identifier#paramSuffix#" ] = { type="cf_sql_varchar", value=arguments.identifier };
		}

		var subquery = $getPresideObject( "website_user" ).selectData(
			  selectFields        = [ "Max( actions.datecreated ) as action_date", "website_user.id" ]
			, filter              = subqueryFilter
			, groupBy             = "website_user.id"
			, getSqlAndParamsOnly = true
			, forceJoins          = "inner"
		);

		return [ { filter=overallFilter, filterParams=params, extraJoins=[ {
			  type           = "inner"
			, subQuery       = subquery.sql
			, subQueryAlias  = subqueryAlias
			, subQueryColumn = "id"
			, joinToTable    = arguments.filterPrefix.len() ? arguments.filterPrefix : ( arguments.parentPropertyName.len() ? arguments.parentPropertyName : "website_user" )
			, joinToColumn   = "id"
		} ] } ];
	}

// PRIVATE HELPERS
	private boolean function _sessionsAreDisabled() {
		var applicationSettings = getApplicationSettings( true );

		return !IsBoolean( applicationSettings.sessionManagement ?: "" ) || !applicationSettings.sessionManagement;
	}

	private string function _getSessionId() {
		var sessionStorage = _getSessionStorage();
		var sessionId      = sessionStorage.getVar( name="_presideSessionId", default="" );

		if ( !Len( Trim( sessionId ) ) ) {
			sessionId = LCase( CreateUUId() );
			sessionStorage.setVar( name="_presideSessionId", value=sessionId );
		}

		return sessionId;
	}

	private boolean function _anonymousTrackingIsDisabled() {
		var trackingEnabled = $getPresideSetting( "tracking", "allow_anonymous_tracking" );

		return !IsBoolean( trackingEnabled ) || !trackingEnabled;
	}

	private string function _getRandomFilterParamSuffix() {
		return CreateUUId().lCase().replace( "-", "", "all" );
	}

// GETTERS AND SETTERS
	private any function _getWebsiteVisitorService() {
		return _websiteVisitorService;
	}
	private void function _setWebsiteVisitorService( required any websiteVisitorService ) {
		_websiteVisitorService = arguments.websiteVisitorService;
	}

	private any function _getSessionStorage() {
		return _sessionStorage;
	}
	private void function _setSessionStorage( required any sessionStorage ) {
		_sessionStorage = arguments.sessionStorage;
	}
}