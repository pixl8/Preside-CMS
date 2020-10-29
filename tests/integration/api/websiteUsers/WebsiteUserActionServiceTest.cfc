component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "recordAction()", function(){
			it( "should save the action to the database, serializing the detail to json", function(){
				var service    = _getService();
				var dbId       = CreateUUId();
				var userId     = CreateUUId();
				var visitorId  = CreateUUId();
				var action     = "logout";
				var type       = "login";
				var identifier = CreateUUId();
				var detail     = { test=CreateUUId() };
				var sessionId  = CreateUUId();

				mockVisitorService.$( "getVisitorId", visitorId );
				mockActionDao.$( "insertData" ).$args( {
					  user       = userId
					, visitor    = visitorId
					, action     = action
					, type       = type
					, detail     = SerializeJson( detail )
					, uri        = cgi.request_url
					, user_ip    = cgi.remote_addr
					, user_agent = cgi.http_user_agent
					, session_id = sessionId
					, identifier = identifier
				} ).$results( dbId );

				service.$( "_getSessionId", sessionId )

				var actionId = service.recordAction(
					  userId     = userId
					, action     = action
					, type       = type
					, detail     = detail
					, identifier = identifier
				);

				expect( actionId ).toBe( dbId );
			} );

			it( "should not record anything when both visitorID and user ID is blank", function(){
				var service    = _getService();
				var action     = "logout";
				var type       = "login";
				var identifier = CreateUUId();
				var detail     = { test=CreateUUId() };
				var sessionId  = CreateUUId();

				mockVisitorService.$( "getVisitorId", "" );
				mockActionDao.$( "insertData" );

				service.$( "_getSessionId", sessionId )

				var actionId = service.recordAction(
					  action     = action
					, type       = type
					, detail     = detail
					, identifier = identifier
				);

				expect( actionId ).toBe( "" );

				expect( mockActionDao.$callLog().insertData.len() ).toBe( 0 );
			} );

			it( "should not record anything when user ID is blank and anonymous tracking is disabled", function(){
				var service    = _getService();
				var action     = "logout";
				var type       = "login";
				var identifier = CreateUUId();
				var detail     = { test=CreateUUId() };
				var sessionId  = CreateUUId();

				mockVisitorService.$( "getVisitorId", CreateUUId() );
				mockActionDao.$( "insertData", CreateUUId() );
				service.$( "$getPresideSetting" ).$args( "tracking", "allow_anonymous_tracking" ).$results( false );
				service.$( "_getSessionId", sessionId )

				var actionId = service.recordAction(
					  action     = action
					, type       = type
					, detail     = detail
					, identifier = identifier
				);

				expect( actionId ).toBe( "" );

				expect( mockActionDao.$callLog().insertData.len() ).toBe( 0 );
			} );
		} );

		describe( "promoteVisitorActionsToUserActions()", function(){
			it( "should update action records that match the given sessionId and visitor, changing them to using the supplied user ID", function(){
				var service        = _getService();
				var sessionId      = CreateUUId();
				var visitorId      = CreateUUId();
				var userId         = CreateUUId();
				var recordsUpdated = Round( Rand() * 1000 );

				service.$( "_getSessionId", sessionId );
				mockVisitorService.$( "getVisitorId", visitorId );
				mockActionDao.$( "updateData" ).$args(
					  filter = { "website_user_action.session_id" = sessionId, "website_user_action.visitor" = visitorId }
					, data   = { user = userId }
				).$results( recordsUpdated );

				expect( service.promoteVisitorActionsToUserActions( userId = userId ) ).toBe( recordsUpdated );
			} );
		} );

		describe( "getLastPerformedDate()", function(){
			it( "should query the max date for the given type + action that is performed by the given user", function(){
				var service    = _getService();
				var userId     = CreateUUId();
				var type       = "login";
				var action     = "logout";
				var date       = Now();
				var mockResult = QueryNew( 'datecreated', 'date', [ [ date ] ] );

				mockActionDao.$( "selectData" ).$args(
					  selectFields = [ "Max( website_user_action.datecreated ) as datecreated" ]
					, filter       = { "website_user_action.user"=userId, "website_user_action.type"=type, "website_user_action.action"=action }
				).$results( mockResult );

				expect( service.getLastPerformedDate(
					  type   = type
					, action = action
					, userId = userId
				) ).toBe( date );
			} );

			it( "should user visitor id to query when user id is empty", function(){
				var service    = _getService();
				var visitorId  = CreateUUId();
				var type       = "login";
				var action     = "logout";
				var date       = Now();
				var mockResult = QueryNew( 'datecreated', 'date', [ [ date ] ] );

				mockVisitorService.$( "getVisitorId", visitorId );
				mockActionDao.$( "selectData" ).$args(
					  selectFields = [ "Max( website_user_action.datecreated ) as datecreated" ]
					, filter       = { "website_user_action.visitor"=visitorId, "website_user_action.type"=type, "website_user_action.action"=action }
				).$results( mockResult );

				expect( service.getLastPerformedDate(
					  type   = type
					, action = action
				) ).toBe( date );
			} );

			it( "should add an 'identifier' filter when identifiers passed", function(){
				var service     = _getService();
				var visitorId   = CreateUUId();
				var type        = "login";
				var action      = "logout";
				var date        = Now();
				var identifiers = [ CreateUUId(), CreateUUId(), CreateUUId() ];
				var mockResult  = QueryNew( 'datecreated', 'date', [ [ date ] ] );

				mockVisitorService.$( "getVisitorId", visitorId );
				mockActionDao.$( "selectData" ).$args(
					  selectFields = [ "Max( website_user_action.datecreated ) as datecreated" ]
					, filter       = { "website_user_action.visitor"=visitorId, "website_user_action.type"=type, "website_user_action.action"=action, "website_user_action.identifier"=identifiers }
				).$results( mockResult );

				expect( service.getLastPerformedDate(
					  type        = type
					, action      = action
					, identifiers = identifiers
				) ).toBe( date );
			} );
		} );

		describe( "hasPerformedAction()", function(){
			it( "should return true when an action record exists matching the given type, action and user", function(){
				var service    = _getService();
				var userId     = CreateUUId();
				var type       = "login";
				var action     = "logout";

				mockActionDao.$( "dataExists" ).$args(
					  filter       = { "website_user_action.user"=userId, "website_user_action.type"=type, "website_user_action.action"=action }
					, extraFilters = []
				).$results( true );

				expect( service.hasPerformedAction(
					  type   = type
					, action = action
					, userId = userId
				) ).toBeTrue();
			} );

			it( "should return false when no action record exists matching the given type, action and user", function(){
				var service    = _getService();
				var userId     = CreateUUId();
				var type       = "login";
				var action     = "logout";

				mockActionDao.$( "dataExists" ).$args(
					  filter       = { "website_user_action.user"=userId, "website_user_action.type"=type, "website_user_action.action"=action }
					, extraFilters = []
				).$results( false );

				expect( service.hasPerformedAction(
					  type   = type
					, action = action
					, userId = userId
				) ).toBeFalse();
			} );

			it( "should user visitor id to query when user id is empty", function(){
				var service    = _getService();
				var visitorId  = CreateUUId();
				var type       = "login";
				var action     = "logout";

				mockVisitorService.$( "getVisitorId", visitorId );
				mockActionDao.$( "dataExists" ).$args(
					  filter       = { "website_user_action.visitor"=visitorId, "website_user_action.type"=type, "website_user_action.action"=action }
					, extraFilters = []
				).$results( false );

				expect( service.hasPerformedAction(
					  type   = type
					, action = action
				) ).toBeFalse();
			} );

			it( "should add an extra dateFrom filter when a 'dateFrom' date is supplied", function(){
				var service    = _getService();
				var userId     = CreateUUId();
				var type       = "login";
				var action     = "logout";
				var dateFrom   = DateAdd( "d", -20, Now() );

				mockActionDao.$( "dataExists" ).$args(
					  filter       = { "website_user_action.user"=userId, "website_user_action.type"=type, "website_user_action.action"=action }
					, extraFilters = [ { filter="website_user_action.datecreated >= :datefrom", filterParams={ datefrom={ type="timestamp", value=dateFrom } } } ]
				).$results( false );

				expect( service.hasPerformedAction(
					  type     = type
					, action   = action
					, userId   = userId
					, dateFrom = dateFrom
				) ).toBeFalse();
			} );

			it( "should add an extra dateTo filter when a 'dateTo' date is supplied", function(){
				var service = _getService();
				var userId  = CreateUUId();
				var type    = "login";
				var action  = "logout";
				var dateTo  = DateAdd( "d", -20, Now() );

				mockActionDao.$( "dataExists" ).$args(
					  filter       = { "website_user_action.user"=userId, "website_user_action.type"=type, "website_user_action.action"=action }
					, extraFilters = [ { filter="website_user_action.datecreated <= :dateto", filterParams={ dateto={ type="timestamp", value=dateTo } } } ]
				).$results( false );

				expect( service.hasPerformedAction(
					  type   = type
					, action = action
					, userId = userId
					, dateTo = dateTo
				) ).toBeFalse();
			} );

			it( "should add an extra identifier filter when identifier(s) supplied", function(){
				var service     = _getService();
				var userId      = CreateUUId();
				var type        = "login";
				var action      = "logout";
				var identifiers = [ CreateUUId(), CreateUUId(), CreateUUId() ];

				mockActionDao.$( "dataExists" ).$args(
					  filter       = { "website_user_action.user"=userId, "website_user_action.type"=type, "website_user_action.action"=action, "website_user_action.identifier"=identifiers }
					, extraFilters = []
				).$results( false );

				expect( service.hasPerformedAction(
					  type        = type
					, action      = action
					, userId      = userId
					, identifiers = identifiers
				) ).toBeFalse();
			} );
		} );

		describe( "getActionCount()", function(){
			it( "should return result of query matching the given type, action and user", function(){
				var service    = _getService();
				var userId     = CreateUUId();
				var type       = "login";
				var action     = "logout";
				var count      = Int( Rand() * 100 );

				mockActionDao.$( "selectData" ).$args(
					  selectFields = [ "Count(1) as action_count" ]
					, filter       = { "website_user_action.user"=userId, "website_user_action.type"=type, "website_user_action.action"=action }
					, extraFilters = []
				).$results( QueryNew( "action_count", "int", [ [ count ] ] ) );

				expect( service.getActionCount(
					  type   = type
					, action = action
					, userId = userId
				) ).toBe( count );
			} );

			it( "should user visitor id to query when user id is empty", function(){
				var service    = _getService();
				var visitorId  = CreateUUId();
				var type       = "login";
				var action     = "logout";
				var count      = Int( Rand() * 100 );

				mockVisitorService.$( "getVisitorId", visitorId );
				mockActionDao.$( "selectData" ).$args(
					  selectFields = [ "Count(1) as action_count" ]
					, filter       = { "website_user_action.visitor"=visitorId, "website_user_action.type"=type, "website_user_action.action"=action }
					, extraFilters = []
				).$results( QueryNew( "action_count", "int", [ [ count ] ] ) );

				expect( service.getActionCount(
					  type   = type
					, action = action
				) ).toBe( count );
			} );

			it( "should add an extra date filter when a 'dateFrom' date is supplied", function(){
				var service    = _getService();
				var userId     = CreateUUId();
				var type       = "login";
				var action     = "logout";
				var dateFrom   = DateAdd( "d", -20, Now() );
				var count      = Int( Rand() * 100 );

				mockActionDao.$( "selectData" ).$args(
					  selectFields = [ "Count(1) as action_count" ]
					, filter       = { "website_user_action.user"=userId, "website_user_action.type"=type, "website_user_action.action"=action }
					, extraFilters = [ { filter="website_user_action.datecreated >= :datefrom", filterParams={ datefrom={ type="timestamp", value=dateFrom } } } ]
				).$results( QueryNew( "action_count", "int", [ [ count ] ] ) );

				expect( service.getActionCount(
					  type     = type
					, action   = action
					, userId   = userId
					, dateFrom = dateFrom
				) ).toBe( count );
			} );

			it( "should add an extra date filter when a 'dateTo' date is supplied", function(){
				var service = _getService();
				var userId  = CreateUUId();
				var type    = "login";
				var action  = "logout";
				var dateTo  = DateAdd( "d", -20, Now() );
				var count   = Int( Rand() * 100 );

				mockActionDao.$( "selectData" ).$args(
					  selectFields = [ "Count(1) as action_count" ]
					, filter       = { "website_user_action.user"=userId, "website_user_action.type"=type, "website_user_action.action"=action }
					, extraFilters = [ { filter="website_user_action.datecreated <= :dateto", filterParams={ dateto={ type="timestamp", value=dateTo } } } ]
				).$results( QueryNew( "action_count", "int", [ [ count ] ] ) );

				expect( service.getActionCount(
					  type   = type
					, action = action
					, userId = userId
					, dateTo = dateTo
				) ).toBe( count );
			} );

			it( "should add an extra identifier filter when identifier(s) supplied", function(){
				var service     = _getService();
				var userId      = CreateUUId();
				var type        = "login";
				var action      = "logout";
				var dateFrom    = DateAdd( "d", -20, Now() );
				var count       = Int( Rand() * 100 );
				var identifiers = [ CreateUUId(), CreateUUId(), CreateUUId() ];

				mockActionDao.$( "selectData" ).$args(
					  selectFields = [ "Count(1) as action_count" ]
					, filter       = { "website_user_action.user"=userId, "website_user_action.type"=type, "website_user_action.action"=action, "website_user_action.identifier"=identifiers }
					, extraFilters = []
				).$results( QueryNew( "action_count", "int", [ [ count ] ] ) );

				expect( service.getActionCount(
					  type        = type
					, action      = action
					, userId      = userId
					, identifiers = identifiers
				) ).toBe( count );
			} );
		} );

		describe( "getUserPerformedActionFilter()", function(){
			it( "should return a filter to match users that have performed the given action & type", function(){
				var service          = _getService();
				var testAction       = CreateUUId();
				var testType         = CreateUUId();
				var dummySubquerySql = CreateUUId();
				var expected         = [{}];

				expected[ 1 ].filter       = "actionCount#testFilterSuffix#.action_count > 0";
				expected[ 1 ].filterParams = {
					  "action#testFilterSuffix#" = { type="cf_sql_varchar", value=testAction }
					, "type#testFilterSuffix#"   = { type="cf_sql_varchar", value=testType   }
				};
				expected[ 1 ].extraJoins   = [ {
					  type           = "left"
					, subQuery       = dummySubquerySql
					, subQueryAlias  = "actionCount" & testFilterSuffix
					, subQueryColumn = "id"
					, joinToTable    = "website_user"
					, joinToColumn   = "id"
				} ];

				mockUserDao.$( "selectData" ).$args(
					  selectFields        = [ "Count( actions.id ) as action_count", "website_user.id" ]
					, filter              = "actions.action = :action#testFilterSuffix# and actions.type = :type#testFilterSuffix#"
					, groupby             = "website_user.id"
					, getSqlAndParamsOnly = true
					, forceJoins          = "inner"
				).$results( { sql=dummySubquerySql, params={} } );


				var filter = service.getUserPerformedActionFilter(
					  action = testAction
					, type   = testType
				);

				expect( filter ).toBe( expected );
			} );

			it( "should return a filter to match users that have NOT performed the given action when 'has' is false", function(){
				var service          = _getService();
				var testAction       = CreateUUId();
				var testType         = CreateUUId();
				var dummySubquerySql = CreateUUId();
				var expected         = [{}];

				expected[ 1 ].filter       = "( actionCount#testFilterSuffix#.action_count is null or actionCount#testFilterSuffix#.action_count = 0 )";
				expected[ 1 ].filterParams = {
					  "action#testFilterSuffix#" = { type="cf_sql_varchar", value=testAction }
					, "type#testFilterSuffix#"   = { type="cf_sql_varchar", value=testType   }
				};
				expected[ 1 ].extraJoins   = [ {
					  type           = "left"
					, subQuery       = dummySubquerySql
					, subQueryAlias  = "actionCount" & testFilterSuffix
					, subQueryColumn = "id"
					, joinToTable    = "website_user"
					, joinToColumn   = "id"
				} ];

				mockUserDao.$( "selectData" ).$args(
					  selectFields        = [ "Count( actions.id ) as action_count", "website_user.id" ]
					, filter              = "actions.action = :action#testFilterSuffix# and actions.type = :type#testFilterSuffix#"
					, groupby             = "website_user.id"
					, getSqlAndParamsOnly = true
					, forceJoins          = "inner"
				).$results( { sql=dummySubquerySql, params={} } );


				var filter = service.getUserPerformedActionFilter(
					  action = testAction
					, type   = testType
					, has    = false
				);

				expect( filter ).toBe( expected );
			} );

			it( "should add date and identifier filters when passed", function(){
				var service          = _getService();
				var testAction       = CreateUUId();
				var testType         = CreateUUId();
				var identifier       = CreateUUId();
				var dummySubquerySql = CreateUUId();
				var from             = DateAdd( "d", -8, Now() );
				var to               = Now();
				var expected         = [{}];

				expected[ 1 ].filter       = "actionCount#testFilterSuffix#.action_count > 0";
				expected[ 1 ].filterParams = {
					  "action#testFilterSuffix#"      = { type="cf_sql_varchar"  , value=testAction            }
					, "type#testFilterSuffix#"        = { type="cf_sql_varchar"  , value=testType              }
					, "identifiers#testFilterSuffix#" = { type="cf_sql_varchar"  , value=identifier, list=true }
					, "datefrom#testFilterSuffix#"    = { type="cf_sql_timestamp", value=from                  }
					, "dateto#testFilterSuffix#"      = { type="cf_sql_timestamp", value=to                    }
				};
				expected[ 1 ].extraJoins   = [ {
					  type           = "left"
					, subQuery       = dummySubquerySql
					, subQueryAlias  = "actionCount" & testFilterSuffix
					, subQueryColumn = "id"
					, joinToTable    = "website_user"
					, joinToColumn   = "id"
				} ];

				mockUserDao.$( "selectData" ).$args(
					  selectFields        = [ "Count( actions.id ) as action_count", "website_user.id" ]
					, filter              = "actions.action = :action#testFilterSuffix# and actions.type = :type#testFilterSuffix# and actions.datecreated >= :datefrom#testFilterSuffix# and actions.datecreated <= :dateto#testFilterSuffix# and actions.identifier in ( :identifiers#testFilterSuffix# )"
					, groupby             = "website_user.id"
					, getSqlAndParamsOnly = true
					, forceJoins          = "inner"
				).$results( { sql=dummySubquerySql, params={} } );


				var filter = service.getUserPerformedActionFilter(
					  action      = testAction
					, type        = testType
					, dateFrom    = from
					, dateTo      = to
					, identifiers = [ identifier ]
				);

				expect( filter ).toBe( expected );
			} );

			it( "should return multiple individual identifier filters when more than one identifier and 'allIdentifiers' is true", function(){
				var service          = _getService();
				var testAction       = CreateUUId();
				var testType         = CreateUUId();
				var identifiers      = [ CreateUUId(), CreateUUId(), CreateUUId() ];
				var dummySubquerySql = CreateUUId();
				var from             = DateAdd( "d", -8, Now() );
				var to               = Now();
				var expected         = [{}];

				for( var i=1; i<=identifiers.len(); i++ ) {
					expected[ i ].filter       = "actionCount#testFilterSuffix#.action_count > 0";
					expected[ i ].filterParams = {
						  "action#testFilterSuffix#"      = { type="cf_sql_varchar"  , value=testAction                }
						, "type#testFilterSuffix#"        = { type="cf_sql_varchar"  , value=testType                  }
						, "identifiers#testFilterSuffix#" = { type="cf_sql_varchar"  , value=identifiers[i], list=true }
						, "datefrom#testFilterSuffix#"    = { type="cf_sql_timestamp", value=from                      }
						, "dateto#testFilterSuffix#"      = { type="cf_sql_timestamp", value=to                        }
					};
					expected[ i ].extraJoins   = [ {
						  type           = "left"
						, subQuery       = dummySubquerySql
						, subQueryAlias  = "actionCount" & testFilterSuffix
						, subQueryColumn = "id"
						, joinToTable    = "website_user"
						, joinToColumn   = "id"
					} ];

				}

				mockUserDao.$( "selectData" ).$args(
					  selectFields        = [ "Count( actions.id ) as action_count", "website_user.id" ]
					, filter              = "actions.action = :action#testFilterSuffix# and actions.type = :type#testFilterSuffix# and actions.datecreated >= :datefrom#testFilterSuffix# and actions.datecreated <= :dateto#testFilterSuffix# and actions.identifier in ( :identifiers#testFilterSuffix# )"
					, groupby             = "website_user.id"
					, getSqlAndParamsOnly = true
					, forceJoins          = "inner"
				).$results( { sql=dummySubquerySql, params={} } );


				var filter = service.getUserPerformedActionFilter(
					  action         = testAction
					, type           = testType
					, dateFrom       = from
					, dateTo         = to
					, identifiers    = identifiers
					, allIdentifiers = true
				);

				expect( filter ).toBe( expected );
			} );

			it( "should use operator and qty arguments to prepare a filter for comparing number of times action has been performed", function(){
				var service          = _getService();
				var testAction       = CreateUUId();
				var testType         = CreateUUId();
				var identifier       = CreateUUId();
				var qty              = 345;
				var operator         = "gte";
				var dummySubquerySql = CreateUUId();
				var from             = DateAdd( "d", -8, Now() );
				var to               = Now();
				var expected         = [{}];

				expected[ 1 ].filter       = "actionCount#testFilterSuffix#.action_count >= :qty#testFilterSuffix#";
				expected[ 1 ].filterParams = {
					  "action#testFilterSuffix#"      = { type="cf_sql_varchar"  , value=testAction            }
					, "type#testFilterSuffix#"        = { type="cf_sql_varchar"  , value=testType              }
					, "identifiers#testFilterSuffix#" = { type="cf_sql_varchar"  , value=identifier, list=true }
					, "datefrom#testFilterSuffix#"    = { type="cf_sql_timestamp", value=from                  }
					, "dateto#testFilterSuffix#"      = { type="cf_sql_timestamp", value=to                    }
					, "qty#testFilterSuffix#"         = { type="cf_sql_integer"  , value=qty                   }
				};
				expected[ 1 ].extraJoins   = [ {
					  type           = "left"
					, subQuery       = dummySubquerySql
					, subQueryAlias  = "actionCount" & testFilterSuffix
					, subQueryColumn = "id"
					, joinToTable    = "website_user"
					, joinToColumn   = "id"
				} ];

				mockUserDao.$( "selectData" ).$args(
					  selectFields        = [ "Count( actions.id ) as action_count", "website_user.id" ]
					, filter              = "actions.action = :action#testFilterSuffix# and actions.type = :type#testFilterSuffix# and actions.datecreated >= :datefrom#testFilterSuffix# and actions.datecreated <= :dateto#testFilterSuffix# and actions.identifier in ( :identifiers#testFilterSuffix# )"
					, groupby             = "website_user.id"
					, getSqlAndParamsOnly = true
					, forceJoins          = "inner"
				).$results( { sql=dummySubquerySql, params={} } );


				var filter = service.getUserPerformedActionFilter(
					  action      = testAction
					, type        = testType
					, dateFrom    = from
					, dateTo      = to
					, identifiers = [ identifier ]
					, qty         = qty
					, qtyOperator = operator
				);

				expect( filter ).toBe( expected );
			} );
		} );

		describe( "getUserLastPerformedActionFilter()", function(){
			it( "should return filter with no date criteria when both dateFrom and dateTo are empty", function(){
				var service          = _getService();
				var testAction       = CreateUUId();
				var testType         = CreateUUId();
				var dummySubquerySql = CreateUUId();
				var from             = "";
				var to               = "";
				var expected         = [{}];

				expected[ 1 ].filter       = "";
				expected[ 1 ].filterParams = {
					  "action#testFilterSuffix#"      = { type="cf_sql_varchar"  , value=testAction }
					, "type#testFilterSuffix#"        = { type="cf_sql_varchar"  , value=testType   }
				};
				expected[ 1 ].extraJoins   = [ {
					  type           = "inner"
					, subQuery       = dummySubquerySql
					, subQueryAlias  = "lastPerformed" & testFilterSuffix
					, subQueryColumn = "id"
					, joinToTable    = "website_user"
					, joinToColumn   = "id"
				} ];

				mockUserDao.$( "selectData" ).$args(
					  selectFields        = [ "Max( actions.datecreated ) as action_date", "website_user.id" ]
					, filter              = "actions.action = :action#testFilterSuffix# and actions.type = :type#testFilterSuffix#"
					, groupby             = "website_user.id"
					, getSqlAndParamsOnly = true
					, forceJoins          = "inner"
				).$results( { sql=dummySubquerySql, params={} } );


				var filter = service.getUserLastPerformedActionFilter(
					  action      = testAction
					, type        = testType
					, dateFrom    = from
					, dateTo      = to
				);

				expect( filter ).toBe( expected );
			} );

			it( "should return filter for date matching the last performed date of the given action / type", function(){
				var service          = _getService();
				var testAction       = CreateUUId();
				var testType         = CreateUUId();
				var dummySubquerySql = CreateUUId();
				var from             = DateAdd( "d", -8, Now() );
				var to               = Now();
				var expected         = [{}];

				expected[ 1 ].filter       = "lastPerformed#testFilterSuffix#.action_date >= :datefrom#testFilterSuffix# and lastPerformed#testFilterSuffix#.action_date <= :dateto#testFilterSuffix#";
				expected[ 1 ].filterParams = {
					  "action#testFilterSuffix#"      = { type="cf_sql_varchar"  , value=testAction }
					, "type#testFilterSuffix#"        = { type="cf_sql_varchar"  , value=testType   }
					, "datefrom#testFilterSuffix#"    = { type="cf_sql_timestamp", value=from       }
					, "dateto#testFilterSuffix#"      = { type="cf_sql_timestamp", value=to         }
				};
				expected[ 1 ].extraJoins   = [ {
					  type           = "inner"
					, subQuery       = dummySubquerySql
					, subQueryAlias  = "lastPerformed" & testFilterSuffix
					, subQueryColumn = "id"
					, joinToTable    = "website_user"
					, joinToColumn   = "id"
				} ];

				mockUserDao.$( "selectData" ).$args(
					  selectFields        = [ "Max( actions.datecreated ) as action_date", "website_user.id" ]
					, filter              = "actions.action = :action#testFilterSuffix# and actions.type = :type#testFilterSuffix#"
					, groupby             = "website_user.id"
					, getSqlAndParamsOnly = true
					, forceJoins          = "inner"
				).$results( { sql=dummySubquerySql, params={} } );


				var filter = service.getUserLastPerformedActionFilter(
					  action      = testAction
					, type        = testType
					, dateFrom    = from
					, dateTo      = to
				);

				expect( filter ).toBe( expected );
			} );

			it( "should should add an identifier filter when identifier passed", function(){
				var service          = _getService();
				var testAction       = CreateUUId();
				var testType         = CreateUUId();
				var dummySubquerySql = CreateUUId();
				var identifier       = CreateUUId();
				var from             = DateAdd( "d", -8, Now() );
				var to               = Now();
				var expected         = [{}];

				expected[ 1 ].filter       = "lastPerformed#testFilterSuffix#.action_date >= :datefrom#testFilterSuffix# and lastPerformed#testFilterSuffix#.action_date <= :dateto#testFilterSuffix#";
				expected[ 1 ].filterParams = {
					  "action#testFilterSuffix#"     = { type="cf_sql_varchar"  , value=testAction }
					, "type#testFilterSuffix#"       = { type="cf_sql_varchar"  , value=testType   }
					, "datefrom#testFilterSuffix#"   = { type="cf_sql_timestamp", value=from       }
					, "dateto#testFilterSuffix#"     = { type="cf_sql_timestamp", value=to         }
					, "identifier#testFilterSuffix#" = { type="cf_sql_varchar"  , value=identifier }
				};
				expected[ 1 ].extraJoins   = [ {
					  type           = "inner"
					, subQuery       = dummySubquerySql
					, subQueryAlias  = "lastPerformed" & testFilterSuffix
					, subQueryColumn = "id"
					, joinToTable    = "website_user"
					, joinToColumn   = "id"
				} ];

				mockUserDao.$( "selectData" ).$args(
					  selectFields        = [ "Max( actions.datecreated ) as action_date", "website_user.id" ]
					, filter              = "actions.action = :action#testFilterSuffix# and actions.type = :type#testFilterSuffix# and actions.identifier = :identifier#testFilterSuffix#"
					, groupby             = "website_user.id"
					, getSqlAndParamsOnly = true
					, forceJoins          = "inner"
				).$results( { sql=dummySubquerySql, params={} } );


				var filter = service.getUserLastPerformedActionFilter(
					  action      = testAction
					, type        = testType
					, dateFrom    = from
					, dateTo      = to
					, identifier  = identifier
				);

				expect( filter ).toBe( expected );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService() {
		mockVisitorService = createEmptyMock( "preside.system.services.websiteUsers.WebsiteVisitorService" );
		mockSessionStorage = createStub();
		configuredActions = {
			  login = [ "test", "this", "stuff" ]
			, test  = [ "this", "stuff" ]
		}

		var service = createMock( object=new preside.system.services.websiteUsers.WebsiteUserActionService(
			  configuredActions     = configuredActions
			, websiteVisitorService = mockVisitorService
			, sessionStorage        = mockSessionStorage
		) );

		mockActionDao    = CreateStub();
		mockUserDao      = CreateStub();
		testFilterSuffix = "_testsuffix";


		service.$( "$getPresideObject" ).$args( "website_user_action" ).$results( mockActionDao );
		service.$( "$getPresideObject" ).$args( "website_user" ).$results( mockUserDao );
		service.$( "$getPresideSetting" ).$args( "tracking", "allow_anonymous_tracking" ).$results( true );
		service.$( "_getRandomFilterParamSuffix", testFilterSuffix );

		return service;
	}
}