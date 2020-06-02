/**
 * Expression handler for "Last email to user bounced" expression
 *
 * @expressionCategory email
 * @expressionContexts user
 * @feature            websiteusers
 */
component {

	property name="userDao" inject="presidecms:object:website_user";

	private boolean function evaluateExpression() {
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
		  string parentPropertyName = ""
		, string filterPrefix       = ""
	){
		var paramSuffix = CreateUUId().lCase().replace( "-", "", "all" );
		var params      = {
			"bounced#paramSuffix#" = { type="cf_sql_boolean", value=true }
		};

		var subQuery = userDao.selectData(
			  selectFields        = [ "Max( email_logs.datecreated ) as log_date", "website_user.id" ]
			, groupBy             = "website_user.id"
			, forceJoins          = "inner"
			, getSqlAndParamsOnly = true
		);
		var subQueryAlias = "emailLogCount" & CreateUUId().lCase().replace( "-", "", "all" );
		var filterSql     = "email_logs.hard_bounced = :bounced#paramSuffix# and email_logs.datecreated = #subQueryAlias#.log_date";

		return [ { filter=filterSql, filterParams=params, extraJoins=[ {
			  type           = "inner"
			, subQuery       = subQuery.sql
			, subQueryAlias  = subQueryAlias
			, subQueryColumn = "id"
			, joinToTable    = filterPrefix.len() ? filterPrefix : ( parentPropertyName.len() ? parentPropertyName : "website_user" )
			, joinToColumn   = "id"
		} ] } ];
	}

}