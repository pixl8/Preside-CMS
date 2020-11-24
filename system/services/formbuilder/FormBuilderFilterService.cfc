/**
 * Provides logic around filters in form builder
 *
 * @autodoc
 * @singleton
 * @presideservice
 */
component {

// CONSTRUCTOR
	/**
	* @formBuilderService.inject                 formBuilderService
	* @rulesEngineConditionService.inject        rulesEngineConditionService
	 */

	 public any function init(
	 	  required any formBuilderService
	 	, required any rulesEngineConditionService
	 ) {
		_setFormBuilderService( arguments.formBuilderService );
		_setRulesEngineConditionService( arguments.rulesEngineConditionService );

		return this;
	}

	public boolean function userQuestionResponseMatchesCondition(
		  string conditionId
		, string formId
		, string submissionId
	) {

		if ( !$isWebsiteUserLoggedIn() ) {
			return false;
		}

		if ( !len( trim( arguments.conditionId ) ) ) {
			return false;
		}


		return _getRulesEngineConditionService().evaluateCondition(
				  conditionId      = arguments.conditionId
				, context          = "webrequest"
				, payload          = {
					  formId       = arguments.formId
					, submissionId = arguments.submissionId
				}
 		);
	}


	public array function prepareFilterForUserLatestResponseMatrixAnyRowMatches(
		  required string question
		, required string value
		,          string formId             = ""
		,          boolean _all              = false
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		var paramSuffix         = _getRandomFilterParamSuffix();
		var responseQueryAlias  = "responseCount" & paramSuffix;
		var overallFilter       = "#responseQueryAlias#.response_count >= 1 ";
		var params              = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
			, "form#paramSuffix#" = { value=arguments.formId, type="cf_sql_varchar" }
		};

		return _prepareFilterForLatestResponseMatrixMatches(
			  value              = arguments.value
			, formId             = arguments.formId
			, _all               = arguments._all
			, responseQueryAlias = responseQueryAlias
			, initialParams      = params
			, paramSuffix        = paramSuffix
			, overallFilter      = overallFilter
			, filterPrefix       = arguments.filterPrefix
			, parentPropertyName = arguments.parentPropertyName
		);
	}

	public array function prepareFilterForUserLatestResponseMatrixAllRowsMatch(
		  required string question
		, required string value
		,          string formId             = ""
		,          boolean _all              = false
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {

		var theQuestion         = _getFormBuilderService().getQuestion( question );
		var questionConfig      = DeserializeJson( theQuestion.item_type_config );
		var rows                = listToArray( questionConfig.rows, chr(13) & chr(10))
		var totalRows           = len( rows );
		var paramSuffix         = _getRandomFilterParamSuffix();
		var responseQueryAlias  = "responseCount" & paramSuffix;
		var overallFilter       = "#responseQueryAlias#.response_count >= #totalRows# ";
		var params              = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
			, "form#paramSuffix#"     = { value=arguments.formId  , type="cf_sql_varchar" }
		};

		return _prepareFilterForLatestResponseMatrixMatches(
			  value              = arguments.value
			, formId             = arguments.formId
			, _all               = arguments._all
			, responseQueryAlias = responseQueryAlias
			, initialParams      = params
			, paramSuffix        = paramSuffix
			, overallFilter      = overallFilter
			, filterPrefix       = arguments.filterPrefix
			, parentPropertyName = arguments.parentPropertyName
		);
	}
	public array function prepareFilterForUserLatestResponseMatrixRowMatches(
 		  required string question
		, required string row
		, required string value
		,          string formId             = ""
		,          boolean _all              = false
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		var paramSuffix         = _getRandomFilterParamSuffix();
		var responseQueryAlias  = "responseCount" & paramSuffix;
		var overallFilter       = "#responseQueryAlias#.response_count >= 1 ";
		var params              = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
			, "form#paramSuffix#"     = { value=arguments.formId  , type="cf_sql_varchar" }
			, "row#paramSuffix#"      = { value=arguments.row     , type="cf_sql_varchar" }
		};

		return _prepareFilterForLatestResponseMatrixMatches(
			  value              = arguments.value
			, formId             = arguments.formId
			, _all               = arguments._all
			, responseQueryAlias = responseQueryAlias
			, initialParams      = params
			, paramSuffix        = paramSuffix
			, overallFilter      = overallFilter
			, row                = arguments.row
			, filterPrefix       = arguments.filterPrefix
			, parentPropertyName = arguments.parentPropertyName
		);
	}
	public array function prepareFilterForSubmissionQuestionMatrixRowMatches(
		  required string question
		, required string row
		, required string value
		,          boolean _all              = false
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		var paramSuffix    = _getRandomFilterParamSuffix();
		var subqueryAlias  = "responseCount" & paramSuffix;
		var overallFilter  = "#subqueryAlias#.response_count >= 1 ";
		var params         = {
								  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
								, "row#paramSuffix#"      = { value=arguments.row, type="cf_sql_varchar" }
							};

		return _prepareFilterForSubmissionQuestionMatrixMatches(
			  value              = arguments.value
			, _all               = arguments._all
			, subqueryAlias      = subqueryAlias
			, initialParams      = params
			, paramSuffix        = paramSuffix
			, overallFilter      = overallFilter
			, row                = arguments.row
			, filterPrefix       = arguments.filterPrefix
			, parentPropertyName = arguments.parentPropertyName
		);
	}

	public array function prepareFilterForSubmissionQuestionMatrixAnyRowMatches(
		  required string question
		, required string value
		,          boolean _all              = false
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		var paramSuffix    = _getRandomFilterParamSuffix();
		var subqueryAlias  = "responseCount" & paramSuffix;
		var overallFilter  = "#subqueryAlias#.response_count >= 1 ";
		var params         = { "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" } };

		return _prepareFilterForSubmissionQuestionMatrixMatches(
			  value              = arguments.value
			, _all               = arguments._all
			, subqueryAlias      = subqueryAlias
			, initialParams      = params
			, paramSuffix        = paramSuffix
			, overallFilter      = overallFilter
			, filterPrefix       = arguments.filterPrefix
			, parentPropertyName = arguments.parentPropertyName
		);
	}

	public array function prepareFilterForSubmissionQuestionMatrixAllRowsMatch(
		  required string question
		, required string value
		,          boolean _all              = false
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {

		var theQuestion    = _getFormBuilderService().getQuestion( question );
		var questionConfig = DeserializeJson( theQuestion.item_type_config );
		var rows           = listToArray( questionConfig.rows, chr(13) & chr(10))
		var totalRows      = len( rows );
		var paramSuffix    = _getRandomFilterParamSuffix();
		var subqueryAlias  = "responseCount" & paramSuffix;
		var overallFilter  = "#subqueryAlias#.response_count >= #totalRows# ";
		var params         = { "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" } };


		return _prepareFilterForSubmissionQuestionMatrixMatches(
			  value              = arguments.value
			, _all               = arguments._all
			, subqueryAlias      = subqueryAlias
			, initialParams      = params
			, paramSuffix        = paramSuffix
			, overallFilter      = overallFilter
			, filterPrefix       = arguments.filterPrefix
			, parentPropertyName = arguments.parentPropertyName
		);
	}

	public array function prepareFilterForUserLatestResponseToChoiceField(
		  required string  question
		, required string  value
		,          string  formId             = ""
		,          boolean _all               = true
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
	) {
		var paramSuffix    = _getRandomFilterParamSuffix();
		var values         = arguments.value.listToArray();
		var params         = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
			, "response#paramSuffix#" = { value=arguments.value   , type="cf_sql_varchar", list=true }
			, "form#paramSuffix#"     = { value=arguments.formId  , type="cf_sql_varchar" }
		};

		var responseQueryAlias  = "responseQuery" & paramSuffix;
		var latestQueryFilter   = "question = :question#paramSuffix# and response > '' ";

		if ( Len( Trim( arguments.formId ) ) ) {
			latestQueryFilter &= " and submission.form = :form#paramSuffix#";
		}

		var latestQueryAlias    = "latestQuery" & paramSuffix;
		var latestQuery         = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields        = [ "Max( formbuilder_question_response.datemodified ) as datemodified, formbuilder_question_response.website_user" ]
			, groupBy             = "formbuilder_question_response.website_user"
			, filter              = latestQueryFilter
			, getSqlAndParamsOnly = true
		);

		var responseQuery       = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields      = ["Count( distinct id ) as response_count, #latestQueryAlias#.website_user"]
			, extraJoins        = [{
				  type           = "inner"
				, subQuery       = latestQuery.sql
				, subQueryAlias  = latestQueryAlias
				, subQueryColumn = "website_user"
				, joinToColumn   = "website_user"
				, joinToTable    = latestQueryAlias
				, groupBy        = "website_user"
			}]
			, filter              = "formbuilder_question_response.datemodified = #latestQueryAlias#.datemodified and question = :question#paramSuffix# and response in (:response#paramSuffix#) "
			, getSqlAndParamsOnly = true
			, groupBy             = "website_user"
		);

		for( var param in responseQuery.params ) {
			params[ param.name ] = { value=param.value, type=param.type };
		}

		var overallFilter  = "#responseQueryAlias#.response_count >= " & ( arguments._all ? "#values.len()#" : "1" );

		var response = [ {
			  filter=overallFilter
			, filterParams=params, extraJoins=[ {
			 	  type           = "left"
				, subQuery       = responseQuery.sql
				, subQueryAlias  = responseQueryAlias
				, subQueryColumn = "website_user"
				, joinToTable    = "website_user"
				, joinToColumn   = "id"
			  }
			]
		} ];

		return response;
	}

	public array function prepareFilterForSubmissionQuestionResponseMatchesChoiceOptions(
		  required string  question
		, required string  value
		,          boolean _all               = false
		,          string  parentPropertyName = ""
		,
	) {
		var filters        = [];
		var paramSuffix    = _getRandomFilterParamSuffix();
		var values         = arguments.value.listToArray();
		var subqueryAlias  = "responseCount" & paramSuffix;
		var overallFilter  = "#subqueryAlias#.response_count >= " & ( arguments._all ? "#values.len()#" : "1" );
		var subqueryFilter = "question = :question#paramSuffix# and response in (:response#paramSuffix#)";
		var params         = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
			, "response#paramSuffix#" = { value=arguments.value, type="cf_sql_varchar", list=true }
		};

		var subquery = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields        = [ "Count( distinct id ) as response_count", "id", "submission", "submission_reference" ]
			, filter              = subqueryFilter
			, groupBy             = "submission"
			, getSqlAndParamsOnly = true
			, forceJoins          = "inner"
		);

		for( var param in subquery.params ) {
			params[ param.name ] = { value=param.value, type=param.type };
		}

		var response = [ { filter=overallFilter, filterParams=params, extraJoins=[ {
			  type           = "left"
			, subQuery       = subquery.sql
			, subQueryAlias  = subqueryAlias
			, subQueryColumn = "submission"
			, joinToTable    = arguments.filterPrefix.len() ? arguments.filterPrefix : ( arguments.parentPropertyName.len() ? arguments.parentPropertyName : "formbuilder_formsubmission" )
			, joinToColumn   = "id"
		} ] } ];

		return response;
	}

	public boolean function evaluateQuestionSubmissionResponseMatch(
			  required string userId
			, required array extraFilters
			,          string formId
			,          string submissionId

	) {
		var submissionsDao = $getPresideObject( "formbuilder_formsubmission" );

		var filter = {
			submitted_by = arguments.userId
	  	}

	  	if ( len( arguments.formId ) ) {
	  		filter.form = arguments.formId;
	  	}

	  	if ( len( arguments.submissionId ) ) {
	  		filter.id = arguments.submissionId;
	  	}

		result.records = submissionsDao.selectData(
			  filter       = filter
			, extraFilters = arguments.extraFilters
			, selectFields = [
				  "formbuilder_formsubmission.id"
			]
		);

		return len (result.records );
	}

	public boolean function evaluateQuestionUserLatestResponseMatch(
			  required string userId
			, required array extraFilters
	) {
		var websiteUserDao = $getPresideObject( "website_user" );

		var filter = {
			id = arguments.userId
	  	}

		result.records = websiteUserDao.selectData(
			  filter       = filter
			, extraFilters = arguments.extraFilters
			, selectFields = [
				  "website_user.id"
			]
		);

		return len( result.records );
	}

	public boolean function evaluateQuestionUserHasResponse(
			  required string userId
			, required array extraFilters
	) {
		var websiteUserDao = $getPresideObject( "website_user" );

		var filter = {
			id = arguments.userId
	  	}

		result.records = websiteUserDao.selectData(
			  filter       = filter
			, extraFilters = arguments.extraFilters
			, selectFields = [
				  "website_user.id"
			]
		);

		return len( result.records );
	}


	public array function prepareFilterForSubmissionQuestionHasResponded(
		  required string  question
		,          boolean _has               = true
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
	) {
		var filters        = [];
		var paramSuffix    = _getRandomFilterParamSuffix();
		var subqueryAlias  = "responseCount" & paramSuffix;
		var overallFilter  = _has ? "#subqueryAlias#.response_count > 0" : "ifnull( #subqueryAlias#.response_count, 0 ) = 0 ";
		var subqueryFilter = "question = :question#paramSuffix# and response> '' and response <> '{}' ";
		var params         = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
		};

		var subquery = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields        = [ "Count( distinct id ) as response_count", "id", "submission", "submission_reference" ]
			, filter              = subqueryFilter
			, groupBy             = "submission"
			, getSqlAndParamsOnly = true
			, forceJoins          = "inner"
		);
		for( var param in subquery.params ) {
			params[ param.name ] = { value=param.value, type=param.type };
		}

		var response = [ { filter=overallFilter, filterParams=params, extraJoins=[ {
			  type           = "left"
			, subQuery       = subquery.sql
			, subQueryAlias  = subqueryAlias
			, subQueryColumn = "submission"
			, joinToTable    = arguments.filterPrefix.len() ? arguments.filterPrefix : ( arguments.parentPropertyName.len() ? arguments.parentPropertyName : "formbuilder_formsubmission" )
			, joinToColumn   = "id"
		} ] } ];


		return response;
	}

	public array function prepareFilterForSubmissionQuestionFileUploadTypeMatches(
		  required string  question
		, required string  filetype
		,          boolean _is = true
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
	) {
		var paramSuffix       = _getRandomFilterParamSuffix();
		var subqueryAlias     = "responseCount" & paramSuffix;
		var values            = listToArray( filetype );
		var overallFilter     = "#subqueryAlias#.response_count >= 1";
		var endsWithSubQuery  = "";
		var params            = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
		};
		var i=0;
		for (var val in values) {
			i++;
			endsWithSubQuery &=  " #( i>1 ? " or " : "" )# response like  :response#paramSuffix#_#i# "
			params["response#paramSuffix#_#i#"] = { value="%#val#", type="cf_sql_varchar" }
		}

		var subqueryFilter = "question = :question#paramSuffix# and  #( _is ? "" : " not ")# (#endsWithSubQuery#) ";
		var subquery = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields        = [ "Count( distinct id ) as response_count", "id", "submission", "submission_reference" ]
			, filter              = subqueryFilter
			, groupBy             = "submission"
			, getSqlAndParamsOnly = true
			, forceJoins          = "inner"
		);
		for( var param in subquery.params ) {
			params[ param.name ] = { value=param.value, type=param.type };
		}

		var response = [ { filter=overallFilter, filterParams=params, extraJoins=[ {
			  type           = "left"
			, subQuery       = subquery.sql
			, subQueryAlias  = subqueryAlias
			, subQueryColumn = "submission"
			, joinToTable    = arguments.filterPrefix.len() ? arguments.filterPrefix : ( arguments.parentPropertyName.len() ? arguments.parentPropertyName : "formbuilder_formsubmission" )
			, joinToColumn   = "id"
		} ] } ];

		return response;
	}

	public array function prepareFilterForSubmissionQuestionResponseMatchesText(
		  required string question
		, required string value
		,          string _stringOperator = "contains"
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		var filters        = [];
		var paramSuffix    = _getRandomFilterParamSuffix();
		var subqueryAlias  = "responseCount" & paramSuffix;
		var overallFilter  = "#subqueryAlias#.response_count > 0";
		var subqueryFilter = "question = :question#paramSuffix# and response ${operator} :response#paramSuffix#";
		var params         = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
			, "response#paramSuffix#"      = { value=arguments.value, type="cf_sql_varchar" }
		};

		switch ( _stringOperator ) {
			case "eq":
				subqueryFilter = subqueryFilter.replace( "${operator}", "=" );
			break;
			case "neq":
				subqueryFilter = subqueryFilter.replace( "${operator}", "!=" );
			break;
			case "contains":
				params[ "response#paramSuffix#" ].value = "%#arguments.value#%";
				subqueryFilter = subqueryFilter.replace( "${operator}", "like" );
			break;
			case "startsWith":
				params[ "response#paramSuffix#" ].value = "#arguments.value#%";
				subqueryFilter = subqueryFilter.replace( "${operator}", "like" );
			break;
			case "endsWith":
				params[ "response#paramSuffix#" ].value = "%#arguments.value#";
				subqueryFilter = subqueryFilter.replace( "${operator}", "like" );
			break;
			case "notcontains":
				params[ "response#paramSuffix#" ].value = "%#arguments.value#%";
				subqueryFilter = subqueryFilter.replace( "${operator}", "not like" );
			break;
			case "notstartsWith":
				params[ "response#paramSuffix#" ].value = "#arguments.value#%";
				subqueryFilter = subqueryFilter.replace( "${operator}", "not like" );
			break;
			case "notendsWith":
				params[ "response#paramSuffix#" ].value = "%#arguments.value#";
				subqueryFilter = subqueryFilter.replace( "${operator}", "not like" );
			break;
		}

		var subquery = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields        = [ "Count( distinct id ) as response_count", "id", "submission", "submission_reference" ]
			, filter              = subqueryFilter
			, groupBy             = "submission"
			, getSqlAndParamsOnly = true
			, forceJoins          = "inner"
		);
		for( var param in subquery.params ) {
			params[ param.name ] = { value=param.value, type=param.type };
		}

		var response = [ { filter=overallFilter, filterParams=params, extraJoins=[ {
			  type           = "left"
			, subQuery       = subquery.sql
			, subQueryAlias  = subqueryAlias
			, subQueryColumn = "submission"
			, joinToTable    = arguments.filterPrefix.len() ? arguments.filterPrefix : ( arguments.parentPropertyName.len() ? arguments.parentPropertyName : "formbuilder_formsubmission" )
			, joinToColumn   = "id"
		} ] } ];


		return response;
	}

	public array function prepareFilterForUserHasRespondedToQuestion(
		  required string  question
		,          string  formId             = ""
		,          boolean _has               = true
		,          string  parentPropertyName = ""
		,          string  filterPrefix       = ""
	) {
		var filters        = [];
		var paramSuffix    = _getRandomFilterParamSuffix();
		var params         = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
		};
		var responseQueryFilter = " response > '' and response <> '{}' and question = :question#paramSuffix# ";
		if ( Len( Trim( arguments.formid ) ) ) {
			responseQueryFilter &= " and submission.form = :form#paramSuffix#";
			params[ "form#paramSuffix#" ] = { value=arguments.formId, type="cf_sql_varchar" };
		}

		var responseQueryAlias = "responseQuery" & paramSuffix;
		var responseQuery      = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields        = [ "website_user" ]
			, filter              = responseQueryFilter
			, getSqlAndParamsOnly = true
		);


		for( var param in responseQuery.params ) {
			params[ param.name ] = { value=param.value, type=param.type };
		}

		var filter = "#responseQueryAlias#.website_user is not null";
		if ( !_has ) {
			filter = "#responseQueryAlias#.website_user is null ";
		}
		var response = [ {
			filterParams=params, extraJoins=[ {
			 	  type           = "left"
				, subQuery       = responseQuery.sql
				, subQueryAlias  = responseQueryAlias
				, subQueryColumn = "website_user"
				, joinToTable    = "website_user"
				, joinToColumn   = "id"
			  }
			]
			, filter = filter
		} ];


		return response;

	}

	public array function prepareFilterForUserLatestResponseToTextField(
		  required string question
		, required string value
		,          string formId             = ""
		,          string _stringOperator    = "contains"
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		var filters        = [];
		var paramSuffix    = _getRandomFilterParamSuffix();
		var params         = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
			, "response#paramSuffix#" = { value=arguments.value, type="cf_sql_varchar" }
			, "form#paramSuffix#" = { value=arguments.formId, type="cf_sql_varchar" }
		};

		var responseQueryAlias  = "responseQuery" & paramSuffix;

		var responseQuery        = _prepareLatestResponseQuery(
			  question           = arguments.question
			, formId             = arguments.formId
		  	, paramSuffix        = paramSuffix
			, responseQueryAlias = responseQueryAlias
			, selectFields       = [ "response", "website_user" ]
		);


		for( var param in responseQuery.params ) {
			params[ param.name ] = { value=param.value, type=param.type };
		}

		var overallFilter  = "response ${operator} :response#paramSuffix# ";//#subqueryAlias#.response_count > 0";

		switch ( _stringOperator ) {
			case "eq":
				overallFilter = overallFilter.replace( "${operator}", "=" );
			break;
			case "neq":
				overallFilter = overallFilter.replace( "${operator}", "!=" );
			break;
			case "contains":
				params[ "response#paramSuffix#" ].value = "%#arguments.value#%";
				overallFilter = overallFilter.replace( "${operator}", "like" );
			break;
			case "startsWith":
				params[ "response#paramSuffix#" ].value = "#arguments.value#%";
				overallFilter = overallFilter.replace( "${operator}", "like" );
			break;
			case "endsWith":
				params[ "response#paramSuffix#" ].value = "%#arguments.value#";
				overallFilter = overallFilter.replace( "${operator}", "like" );
			break;
			case "notcontains":
				params[ "response#paramSuffix#" ].value = "%#arguments.value#%";
				overallFilter = overallFilter.replace( "${operator}", "not like" );
			break;
			case "notstartsWith":
				params[ "response#paramSuffix#" ].value = "#arguments.value#%";
				overallFilter = overallFilter.replace( "${operator}", "not like" );
			break;
			case "notendsWith":
				params[ "response#paramSuffix#" ].value = "%#arguments.value#";
				overallFilter = overallFilter.replace( "${operator}", "not like" );
			break;
		}

		var response = [ {
			  filter=overallFilter
			, filterParams=params, extraJoins=[ {
			 	  type           = "left"
				, subQuery       = responseQuery.sql
				, subQueryAlias  = responseQueryAlias
				, subQueryColumn = "website_user"
				, joinToTable    = "website_user"
				, joinToColumn   = "id"
			  }
			]
		} ];

		return response;
	}

	public array function prepareFilterForUserLatestResponseToDateField(
		  required string question
		,          string formId             = ""
		,          struct _time              = {}
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		var overallFilter      = "1=1";
		var paramSuffix        = _getRandomFilterParamSuffix();
		var responseQueryAlias = "responseQuery" & paramSuffix;
		var params             = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
			, "form#paramSuffix#" = { value=arguments.formId, type="cf_sql_varchar" }
		};

		var responseQuery      = _prepareLatestResponseQuery(
			  question           = arguments.question
			, formId             = arguments.formId
		  	, paramSuffix        = paramSuffix
			, responseQueryAlias = responseQueryAlias
			, selectFields       = [ "date_response", "website_user" ]
		);

		for( var param in responseQuery.params ) {
			params[ param.name ] = { value=param.value, type=param.type };
		}


		if ( IsDate( arguments._time.from ?: "" ) ) {
			overallFilter &= " and date( date_response ) >= :from#paramSuffix#";
			params[ "from#paramSuffix#" ] = { value=arguments._time.from, type="cf_sql_timestamp" };
		}
		if ( IsDate( arguments._time.to ?: "" ) ) {
			overallFilter &= " and date( date_response ) <= :to#paramSuffix#";
			params[ "to#paramSuffix#" ] = { value=arguments._time.to, type="cf_sql_timestamp" };
		}

		var response = [ {
			  filter=overallFilter
			, filterParams=params, extraJoins=[ {
			 	  type           = "left"
				, subQuery       = responseQuery.sql
				, subQueryAlias  = responseQueryAlias
				, subQueryColumn = "website_user"
				, joinToTable    = "website_user"
				, joinToColumn   = "id"
			  }
			]
		} ];

		return response;
	}


	public array function prepareFilterForSubmissionQuestionResponseDateComparison (
		  required string question
		, required struct _time
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		var paramSuffix    = _getRandomFilterParamSuffix();
		var subqueryAlias  = "responseCount" & paramSuffix;
		var overallFilter  = "#subqueryAlias#.response_count > 0";
		var subqueryFilter = "question = :question#paramSuffix#";
		var params         = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
		};

		if ( IsDate( arguments._time.from ?: "" ) ) {
			subqueryFilter &= " and date( date_response ) >= :from#paramSuffix#";
			params[ "from#paramSuffix#" ] = { value=arguments._time.from, type="cf_sql_timestamp" };
		}
		if ( IsDate( arguments._time.to ?: "" ) ) {
			subqueryFilter &= " and date( date_response ) <= :to#paramSuffix#";
			params[ "to#paramSuffix#" ] = { value=arguments._time.to, type="cf_sql_timestamp" };
		}

		var subquery = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields        = [ "Count( distinct id ) as response_count", "id", "submission", "submission_reference" ]
			, filter              = subqueryFilter
			, groupBy             = "submission"
			, getSqlAndParamsOnly = true
			, forceJoins          = "inner"
		);
		for( var param in subquery.params ) {
			params[ param.name ] = { value=param.value, type=param.type };
		}

		var response = [ { filter=overallFilter, filterParams=params, extraJoins=[ {
			  type           = "left"
			, subQuery       = subquery.sql
			, subQueryAlias  = subqueryAlias
			, subQueryColumn = "submission"
			, joinToTable    = arguments.filterPrefix.len() ? arguments.filterPrefix : ( arguments.parentPropertyName.len() ? arguments.parentPropertyName : "formbuilder_formsubmission" )
			, joinToColumn   = "id"
		} ] } ];


		return response;
	}

	public array function prepareFilterForUserLatestResponseToNumberField(
		  required string question
		, required string value
		,          string formId             = ""
		,          string _numericOperator   = "eq"
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		var filters        = [];
		var paramSuffix    = _getRandomFilterParamSuffix();
		var params         = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
			, "response#paramSuffix#" = { value=arguments.value, type="cf_sql_varchar" }
			, "form#paramSuffix#"     = { value=arguments.formId, type="cf_sql_varchar" }
		};
		var responseField = "";
		var theQuestion   = _getFormBuilderService().getQuestion( question );

		switch ( theQuestion.item_type )
		{
			case "number":
				var questionConfig = DeserializeJson( theQuestion.item_type_config );

				switch ( questionConfig.format ) {
					case "integer": responseField="int_response";   break;
					case "free"   : responseField="float_response"; break;
					case "price"  : responseField="float_response"; break;
				}
				break;
			case "starRating":
				responseField = "float_response";
				break;
		}

		var responseQueryAlias  = "responseQuery" & paramSuffix;

		var responseQuery        = _prepareLatestResponseQuery(
			  question           = arguments.question
			, formId             = arguments.formId
		  	, paramSuffix        = paramSuffix
			, responseQueryAlias = responseQueryAlias
			, selectFields       = [ responseField, "website_user" ]
		);


		for( var param in responseQuery.params ) {
			params[ param.name ] = { value=param.value, type=param.type };
		}

		var overallFilter  = "cast(#responseQueryAlias#.#responseField# as decimal(12,2) ) ${operator} :response#paramSuffix# ";

		switch ( _numericOperator ) {
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
		}

		var response = [ {
			  filter=overallFilter
			, filterParams=params, extraJoins=[ {
			      type           = "left"
				, subQuery       = responseQuery.sql
				, subQueryAlias  = responseQueryAlias
				, subQueryColumn = "website_user"
				, joinToTable    = "website_user"
				, joinToColumn   = "id"
			  }
			]
		} ];

		return response;
	}

	public array function prepareFilterForSubmissionQuestionResponseMatchesNumber(
		  required string question
		, required string value
		,          string _numericOperator = "eq"
		,          string parentPropertyName = ""
		,          string filterPrefix       = ""
	) {
		var responseField = "";
		var cast          = "int"
		var theQuestion    = _getFormBuilderService().getQuestion( question );

		switch ( theQuestion.item_type )
		{
			case "number":
				var questionConfig = DeserializeJson( theQuestion.item_type_config );

				switch ( questionConfig.format ) {
					case "integer":
						responseField="int_response";
						cast         ="int";
						break;
					case "free"   :
						responseField="float_response";
						cast         ="decimal(12,4)";
						break;
					case "price"  :
						responseField="float_response";
						cast         ="decimal(12,2)";
						break;
				}
				break;
			case "starRating":
				responseField = "float_response";
				cast          = "decimal(12,1)";
				break;
		}

		var filters        = [];
		var paramSuffix    = _getRandomFilterParamSuffix();
		var subqueryAlias  = "responseCount" & paramSuffix;
		var overallFilter  = "#subqueryAlias#.response_count > 0";
		var subqueryFilter = "question = :question#paramSuffix# and cast( #responseField# as #cast#) ${operator} cast( :response#paramSuffix# as #cast# )";
		var params         = {
			  "question#paramSuffix#" = { value=arguments.question, type="cf_sql_varchar" }
			, "response#paramSuffix#" = { value=arguments.value,    type="cf_sql_varchar" }
		};

		switch ( _numericOperator ) {
			case "eq":
				subqueryFilter = subqueryFilter.replace( "${operator}", "=" );
			break;
			case "neq":
				subqueryFilter = subqueryFilter.replace( "${operator}", "!=" );
			break;
			case "gt":
				subqueryFilter = subqueryFilter.replace( "${operator}", ">" );
			break;
			case "gte":
				subqueryFilter = subqueryFilter.replace( "${operator}", ">=" );
			break;
			case "lt":
				subqueryFilter = subqueryFilter.replace( "${operator}", "<" );
			break;
			case "lte":
				subqueryFilter = subqueryFilter.replace( "${operator}", "<=" );
			break;
		}


		var subquery = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields        = [ "Count( distinct id ) as response_count", "id", "submission", "submission_reference" ]
			, filter              = subqueryFilter
			, groupBy             = "submission"
			, getSqlAndParamsOnly = true
			, forceJoins          = "inner"
		);
		for( var param in subquery.params ) {
			params[ param.name ] = { value=param.value, type=param.type };
		}

		var response = [ { filter=overallFilter, filterParams=params, extraJoins=[ {
			  type           = "left"
			, subQuery       = subquery.sql
			, subQueryAlias  = subqueryAlias
			, subQueryColumn = "submission"
			, joinToTable    = arguments.filterPrefix.len() ? arguments.filterPrefix : ( arguments.parentPropertyName.len() ? arguments.parentPropertyName : "formbuilder_formsubmission" )
			, joinToColumn   = "id"
		} ] } ];

		return response;
	}

// PRIVATE HELPERS
	private struct function _prepareLatestResponseQuery(
		  required string question
		, required string formId
		, required string paramSuffix
		, required string responseQueryAlias
		, required array  selectFields
	) {
		var latestQueryFilter = "question = :question#paramSuffix# and response > '' ";
		var latestQueryAlias  = "latestQuery" & paramSuffix;

		if ( Len( Trim( arguments.formId ) ) ) {
			latestQueryFilter &= " and submission.form = :form#paramSuffix#";
		}

		var latestQuery       = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields        = [ "Max( formbuilder_question_response.datemodified ) as datemodified, formbuilder_question_response.website_user" ]
			, groupBy             = "formbuilder_question_response.website_user"
			, filter              = latestQueryFilter
			, getSqlAndParamsOnly = true
		);

		var responseQuery       = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields        = arguments.selectFields
			, extraJoins          = [{
				  type           = "left"
				, subQuery       = latestQuery.sql
				, subQueryAlias  = latestQueryAlias
				, subQueryColumn = "website_user"
				, joinToColumn   = "website_user"
				, joinToTable    = latestQueryAlias
			}]
			, filter              = "formbuilder_question_response.datemodified = #latestQueryAlias#.datemodified and formbuilder_question_response.question = :question#paramSuffix# "
			, getSqlAndParamsOnly = true
			, groupBy             = "formbuilder_question_response.website_user"
		);

		return responseQuery;
	}


	private array function _prepareFilterForLatestResponseMatrixMatches(
		  required string value
		, required string formId
		, required string _all
		, required string filterPrefix
		, required string parentPropertyName
		, required string responseQueryAlias
		, required struct initialParams
		, required string paramSuffix
		, required string overallFilter
		,          string row
	) {
		var params           = initialParams ?: {};
		var latestQueryAlias = "latestQuery" & paramSuffix;
		var andOr            = _all ? " and " : " or ";
		var i                = 0;
		var values           = listToArray( value );
		var andOrSubquery    = "";

		for (var val in values) {
			i++;

			// equals 'value' or startsWith 'value,' or contains ', value' or ends with ', value'
			andOrSubquery &= " #( i>1 ? andOr : "" )# ( "
			andOrSubquery &= " response = :response#paramSuffix#_#i# "
			andOrSubquery &= " or response like concat( :response#paramSuffix#_#i#, ',%' ) "
			andOrSubquery &= " or response like concat( '%, ', :response#paramSuffix#_#i#, ',%' )  "
			andOrSubquery &= " or response like concat( '%, ', :response#paramSuffix#_#i#) ) ";
			params["response#paramSuffix#_#i#"] = { value=val, type="cf_sql_varchar" }
		}

		var responseFilter = "question = :question#paramSuffix# and formbuilder_question_response.datemodified = #latestQueryAlias#.datemodified and ( #andOrSubquery# ) "
		if ( len( arguments.row) ) {
			responseFilter &= "and question_subreference = :row#paramSuffix#";
		}


		var latestQueryFilter = "question = :question#paramSuffix# and response > '' ";

		if ( Len( Trim( arguments.formId ) ) ) {
			latestQueryFilter &= " and submission.form = :form#paramSuffix#";
		}

		var latestQuery       = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields        = [ "Max( formbuilder_question_response.datemodified ) as datemodified, formbuilder_question_response.website_user" ]
			, groupBy             = "formbuilder_question_response.website_user"
			, filter              = latestQueryFilter
			, getSqlAndParamsOnly = true
		);

		var responseQuery       = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields        = [ "Count( distinct id ) as response_count", "website_user" ]
			, extraJoins  = [{
				  type           = "inner"
				, subQuery       = latestQuery.sql
				, subQueryAlias  = latestQueryAlias
				, subQueryColumn = "website_user"
				, joinToColumn   = "website_user"
				, joinToTable    = latestQueryAlias
			}]
			, filter = responseFilter
			, groupBy = "website_user"
			, getSqlAndParamsOnly = true
		);

		for( var param in responseQuery.params ) {
			params[ param.name ] = { value=param.value, type=param.type };
		}

		var response = [ { filter=overallFilter, filterParams=params, extraJoins=[ {
			  type           = "left"
			, subQuery       = responseQuery.sql
			, subQueryAlias  = arguments.responseQueryAlias
			, subQueryColumn = "website_user"
			, joinToTable    = "website_user"
				, joinToColumn   = "id"
		} ] } ];

		return response;
	}
	private array function _prepareFilterForSubmissionQuestionMatrixMatches(
		  required string value
		, required string _all
		, required string filterPrefix
		, required string parentPropertyName
		, required string subqueryAlias
		, required struct initialParams
		, required string paramSuffix
		, required string overallFilter
		,          string row

	) {

		var params         = initialParams ?: {};
		var andOr          = _all ? " and " : " or ";
		var i              = 0;
		var values         = listToArray( value );
		var andOrSubquery  = "";

		for (var val in values) {
			i++;

			// equals 'value' or startsWith 'value,' or contains ', value' or ends with ', value'
			andOrSubquery &=  " #( i>1 ? andOr : "" )# ( "
			andOrSubquery &=  " response = :response#paramSuffix#_#i# "
			andOrSubquery &=  " or response like concat( :response#paramSuffix#_#i#, ',%' ) "
			andOrSubquery &=  " or response like concat( '%, ', :response#paramSuffix#_#i#, ',%' )  "
			andOrSubquery &=  " or response like concat( '%, ', :response#paramSuffix#_#i#) ) ";
			params["response#paramSuffix#_#i#"] = { value=val, type="cf_sql_varchar" }
		}

		var subqueryFilter = "question = :question#paramSuffix#  and ( #andOrSubquery# ) "
		if ( len( arguments.row) ) {
			subqueryFilter &= "and question_subreference = :row#paramSuffix#";
		}


		var subquery = $getPresideObject( "formbuilder_question_response" ).selectData(
			  selectFields        = [ "Count( distinct id ) as response_count", "id", "submission", "submission_reference" ]
			, filter              = subqueryFilter
			, groupBy             = "submission"
			, getSqlAndParamsOnly = true
			, forceJoins          = "inner"
		);
		for( var param in subquery.params ) {
			params[ param.name ] = { value=param.value, type=param.type };
		}

		var response = [ { filter=overallFilter, filterParams=params, extraJoins=[ {
			  type           = "left"
			, subQuery       = subquery.sql
			, subQueryAlias  = arguments.subqueryAlias
			, subQueryColumn = "submission"
			, joinToTable    = arguments.filterPrefix.len() ? arguments.filterPrefix : ( arguments.parentPropertyName.len() ? arguments.parentPropertyName : "formbuilder_formsubmission" )
			, joinToColumn   = "id"
		} ] } ];


		return response;
	}
// GETTERS AND SETTERS
	private string function _getRandomFilterParamSuffix() {
		return CreateUUId().lCase().replace( "-", "", "all" );
	}

	private any function _getFormBuilderService() {
		return _formBuilderService;
	}
	private void function _setFormBuilderService( required any formBuilderService ) {
		_formBuilderService = arguments.formBuilderService;
	}

	private any function _getRulesEngineConditionService() {
		return _rulesEngineConditionService;
	}
	private void function _setRulesEngineConditionService( required any rulesEngineConditionService ) {
		_rulesEngineConditionService = arguments.rulesEngineConditionService;
	}
}