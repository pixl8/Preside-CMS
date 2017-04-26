/**
 * Expression handler for "User email interaction" expression
 *
 * @expressionCategory email
 * @expressionContexts user
 * @feature            websiteusers
 */
component {

	property name="userDao" inject="presidecms:object:website_user";

	/**
	 * @templates.fieldtype     object
	 * @templates.object        email_template
	 * @templates.objectFilters webUserEmailTemplates
	 * @templates.multiple      true
	 * @action.fieldtype        enum
	 * @action.enum             emailAction
	 * @action.multiple         false
	 *
	 */
	private boolean function evaluateExpression(
		  string  templates = ""
		, string  action    = "opened"
		, boolean _has      = true
		, struct  _pastTime = {}
	) {
		var userId = payload.user.id ?: "";

		if ( !userId.len() ) {
			return false;
		}

		return userDao.dataExists(
			  id           = userId
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	/**
	 * @objects website_user
	 *
	 */
	private array function prepareFilters(
		  string  templates          = ""
		, string  action             = "opened"
		, boolean _has               = true
		, struct  _pastTime          = {}
		, string  parentPropertyName = ""
		, string  filterPrefix       = ""
	){
		var subqueryfilters = "";
		var params          = {};
		var paramSuffix     = CreateUUId().lCase().replace( "-", "", "all" );
		var datefield       = "datecreated";
		var actionParamName = "action" & paramSuffix;
		var countField      = "email_logs.id";

		params[ actionParamName ] = { type="cf_sql_boolean", value=true };

		switch( arguments.action ) {
			case "sent":
				subqueryFilters = "email_logs.sent = :#actionParamName#";
				datefield = "sent_date";
			break;
			case "received":
				subqueryFilters = "email_logs.delivered = :#actionParamName#";
				datefield = "delivered_date";
			break;
			case "failed":
				subqueryFilters = "email_logs.failed = :#actionParamName#";
				datefield = "failed_date";
			break;
			case "bounced":
				subqueryFilters = "email_logs.hard_bounced = :#actionParamName#";
				datefield = "hard_bounced_date";
			break;
			case "opened":
				subqueryFilters = "email_logs.opened = :#actionParamName#";
				datefield = "opened_date";
			break;
			case "markedasspam":
				subqueryFilters = "email_logs.marked_as_spam = :#actionParamName#";
				datefield = "marked_as_spam_date";
			break;
			case "clicked":
				subqueryFilters           = "email_logs$activities.activity_type = :#actionParamName#";
				params[ actionParamName ] = { type="cf_sql_varchar", value="click" };
				datefield                 = "email_logs$activities.datecreated";
				countField                = "email_logs$activities.id";
			break;
		}


		if ( Len( Trim( arguments.templates ) ) ) {
			params[ "templates" & paramSuffix ] = { type="cf_sql_varchar", value=arguments.templates, list=true };
			subqueryFilters &= " and email_logs.email_template in (:templates#paramSuffix#)";
		}
		if ( isDate( arguments._pastTime.from ?: "" ) ) {
			params[ "datefrom" & paramSuffix ] = { type="cf_sql_timestamp", value=arguments._pastTime.from };
			subqueryFilters &= " and email_logs.#datefield# >= :datefrom#paramSuffix#";
		}
		if ( isDate( arguments._pastTime.to ?: "" ) ) {
			params[ "dateto" & paramSuffix ] = { type="cf_sql_timestamp", value=arguments._pastTime.to };
			subqueryFilters &= " and email_logs.#datefield# <= :dateto#paramSuffix#";
		}

		var subQuery = userDao.selectData(
			  selectFields        = [ "Count( #countField# ) as log_count", "website_user.id" ]
			, groupBy             = "website_user.id"
			, filter              = subqueryfilters
			, forceJoins          = "inner"
			, getSqlAndParamsOnly = true
		);
		var subQueryAlias = "emailLogCount" & CreateUUId().lCase().replace( "-", "", "all" );
		var filterSql     = "";

		if ( arguments._has ) {
			filterSql = "#subQueryAlias#.log_count > 0";
		} else {
			filterSql = "( #subQueryAlias#.log_count is null or #subQueryAlias#.log_count = 0 )";
		}

		return [ { filter=filterSql, filterParams=params, extraJoins=[ {
			  type           = arguments._has ? "inner" : "left"
			, subQuery       = subQuery.sql
			, subQueryAlias  = subQueryAlias
			, subQueryColumn = "id"
			, joinToTable    = filterPrefix.len() ? filterPrefix : ( parentPropertyName.len() ? parentPropertyName : "website_user" )
			, joinToColumn   = "id"
		} ] } ];
	}

}