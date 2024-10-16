/**
 * A service to abstract logic for dealing with
 * summary statistic logging for email templates
 *
 * @singleton      true
 * @presideService true
 * @feature        emailCenter
 */
component {

	property name="sqlRunner"       inject="sqlRunner";
	property name="timeSeriesUtils" inject="timeSeriesUtils";

	property name="templateDao"          inject="presidecms:object:email_template";
	property name="statsSummaryDao"      inject="presidecms:object:email_template_stats";
	property name="clickStatsSummaryDao" inject="presidecms:object:email_template_click_stats";
	property name="activityDao"          inject="presidecms:object:email_template_send_log_activity";

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public any function recordHit(
		  required string  emailTemplateId
		, required date    hitDate
		, required string  hitStat
		,          struct  data       = {}
		,          numeric hitCount   = 1
		,          boolean first = false
	) {
		sqlRunner.runSql(
			  dsn        = _getDsn()
			, sql        = _getRecordHitSql( arguments.hitStat )
			, params     = _prepareHitRecordParams( argumentCollection=arguments )
			, returnType = "info"
		);

		if ( arguments.hitStat == "click" ) {
			_recordClick(
				  argumentCollection = arguments.data
				, emailTemplateId    = arguments.emailTemplateId
				, hitDate            = arguments.hitDate
				, clicCount          = arguments.hitCount
			);
		}
		if ( arguments.first ) {
			if ( arguments.hitStat == "open" ) {
				recordHit( argumentCollection=arguments, hitCount=1, hitStat="unique_open" );
			}
			if ( arguments.hitStat == "click" ) {
				recordHit( argumentCollection=arguments, hitCount=1, hitStat="unique_click" );
			}
		}
	}

	public any function _recordClick(
		  required string  emailTemplateId
		, required date    hitDate
		,          string  link       = ""
		,          string  link_body  = ""
		,          string  link_title = ""
		,          numeric clickCount = 1
	) {
		if ( !Len( arguments.link ) ) {
			return;
		}

		sqlRunner.runSql(
			  dsn        = _getDsn()
			, sql        = _getRecordClickSql()
			, params     = _prepareClickRecordParams( argumentCollection=arguments )
			, returnType = "info"
		);
	}

	public numeric function getStatCount(
		  required string templateId
		, required string field
		,          any    dateFrom = ""
		,          any    dateTo   = ""
	) {
		return Val( statsSummaryDao.selectData(
			  selectFields = [ "sum( #_validateStatField( arguments.field )# ) as stat_count" ]
			, filter       = { template=arguments.templateId }
			, extraFilters = _getEmailLogPerformanceDateFilters( argumentCollection=arguments )
		).stat_count );
	}

	public struct function getSummaryStats( required string templateId ) {
		var stats = {
			  sendCount        = getStatCount( templateId=arguments.templateId, field="send_count"         )
			, deliveryCount    = getStatCount( templateId=arguments.templateId, field="delivery_count"     )
			, bounceCount      = getStatCount( templateId=arguments.templateId, field="fail_count"         )
			, uniqueOpenCount  = getStatCount( templateId=arguments.templateId, field="unique_open_count"  )
			, totalOpenCount   = getStatCount( templateId=arguments.templateId, field="open_count"         )
			, uniqueClickCount = getStatCount( templateId=arguments.templateId, field="unique_click_count" )
			, totalClickCount  = getStatCount( templateId=arguments.templateId, field="click_count"        )
			, unsubscribeCount = getStatCount( templateId=arguments.templateId, field="unsubscribe_count"  )
			, complaintCount   = getStatCount( templateId=arguments.templateId, field="spam_count"         )
			, botOpenCount     = getStatCount( templateId=arguments.templateId, field="bot_open_count"     )
			, botClickCount    = getStatCount( templateId=arguments.templateId, field="bot_click_count"    )
		};

		if ( ( stats.bounceCount + stats.deliveryCount ) > stats.sendCount ) {
			stats.bounceCount = stats.sendCount - stats.deliveryCount; // rough adjustment to avoid confusion when emails soft bounce and then become delivered (https://presidecms.atlassian.net/browse/PRESIDECMS-2951)
		}

		stats.deliveryRate     = stats.sendCount        ? ( ( stats.deliveryCount    / stats.sendCount       ) * 100 ) : 0;
		stats.bounceRate       = stats.sendCount        ? ( ( stats.bounceCount      / stats.sendCount       ) * 100 ) : 0;
		stats.unsubscribeRate  = stats.sendCount        ? ( ( stats.unsubscribeCount / stats.sendCount       ) * 100 ) : 0;
		stats.openRate         = stats.sendCount        ? ( ( stats.uniqueOpenCount  / stats.sendCount       ) * 100 ) : 0;
		stats.clickThroughRate = stats.sendCount        ? ( ( stats.uniqueClickCount / stats.sendCount       ) * 100 ) : 0;
		stats.complaintRate    = stats.sendCount        ? ( ( stats.complaintCount   / stats.sendCount       ) * 100 ) : 0;
		stats.clickToOpenRate  = stats.uniqueClickCount ? ( ( stats.uniqueClickCount / stats.uniqueOpenCount ) * 100 ) : 0;
		stats.hasClicks        = stats.totalClickCount  > 0;
		stats.hasBounces       = stats.bounceCount      > 0;
		stats.hasUnsubscribes  = stats.unsubscribeCount > 0;
		stats.hasComplaints    = stats.complaintCount   > 0;

		return stats;
	}

	public struct function getStatsOverTime(
		  required string  templateId
		, required string  dateFrom
		, required string  dateTo
		,          numeric timePoints = 1
		,          boolean uniqueOpens = ( arguments.timePoints == 1 )
		,          array   stats = []
	) {
		var timeResolution  = timeSeriesUtils.calculateTimeResolution( arguments.dateFrom, arguments.dateTo, "h" );
		var dates           = timeSeriesUtils.getExpectedTimes( timeResolution, arguments.dateFrom, arguments.dateTo );
		var commonArgs      = {
			  timeResolution    = timeResolution
			, expectedTimes     = dates
			, sourceObject      = "email_template_stats"
			, startDate         = arguments.dateFrom
			, endDate           = arguments.dateTo
			, valuesOnly        = true
			, aggregateFunction = "sum"
			, timeField         = "hour_start"
			, timeFieldIsEpoch  = true
			, epochResolution   = "h"
			, minResolution     = "h"
			, extraFilters      = [ { filter={ template=arguments.templateId } } ]
		};
		var statMappings = {
			  sent         = "send_count"
			, delivered    = "delivery_count"
			, failed       = "fail_count"
			, opened       = "open_count"
			, clicks       = "click_count"
			, unsubscribes = "unsubscribe_count"
			, complaints   = "spam_count"
		};

		var stats = { dates = dates };
		for( var stat in statMappings ) {
			if ( !ArrayLen( arguments.stats ) || ArrayFindNoCase( arguments.stats, stat ) ) {
				stats[ stat ] = timeSeriesUtils.getTimeSeriesData( argumentCollection=commonArgs, aggregateOver=statMappings[ stat ] );
			}
		}

		for( var i=1; i <= ArrayLen( stats.dates ); i++ ) {
			stats.dates[ i ] = DateTimeFormat( stats.dates[ i ], "yyyy-mm-dd HH:nn" );
		}

		return stats;
	}

	public struct function getLinkClickStats(
		  required string templateId
		,          string dateFrom = ""
		,          string dateTo   = ""
	) {
		var extraFilters  = _getEmailLogPerformanceDateFilters( argumentCollection=arguments );
		var clickStats    = StructNew( "ordered" );
		var rawClickStats = clickStatsSummaryDao.selectData(
			  filter       = { template=arguments.templateId }
			, selectFields = [ "sum( click_count ) as summed_count", "link_hash", "link", "link_title", "link_body" ]
			, extraFilters = extraFilters
			, groupBy      = "link_hash"
			, orderBy      = "summed_count desc"
		);

		for( var link in rawClickStats ) {
			if ( !StructKeyExists( clickStats, link.link_body ) ) {
				clickStats[ link.link_body ] = {
					  links      = []
					, totalCount = 0
				};
			}

			ArrayAppend( clickStats[ link.link_body ].links, {
				  link       = link.link
				, title      = link.link_title
				, body       = link.link_body
				, clickCount = link.summed_count
			} );

			clickStats[ link.link_body ].totalCount += link.summed_count;
		}

		return clickStats;
	}

	public function getFirstStatDate( required string templateId ) {
		var earliest = statsSummaryDao.selectData(
			  selectFields = [ "min( hour_start ) as first_hour" ]
			, filter       = { template=arguments.templateId }
		);

		if ( earliest.recordCount && Val( earliest.first_hour ) ) {
			return DateAdd( "h", earliest.first_hour, "1970-01-01" );
		}

		return "";
	}

	public function getLastStatDate( required string templateId ) {
		var latest = statsSummaryDao.selectData(
			  selectFields = [ "max( hour_start ) as last_hour" ]
			, filter = { template=arguments.templateId }
		);

		if ( latest.recordCount && Val( latest.last_hour ) ) {
			return DateAdd( "h", latest.last_hour+1, "1970-01-01" );
		}

		return "";
	}

	public void function migrateToSummaryTables() {
		var emailTemplate = "";

		_resetTmpExtensionMigration();

		do {
			emailTemplate = templateDao.selectData(
				  selectFields       = [ "id", "_version_is_draft" ]
				, filter             = "stats_collection_enabled is null or stats_collection_enabled = :stats_collection_enabled"
				, filterParams       = { stats_collection_enabled=false }
				, maxrows            = 1
				, orderBy            = "datecreated desc"
				, useCache           = false
				, allowDraftVersions = true
			);

			if ( emailTemplate.recordCount ) {
				_migrateTemplateToSummaryTables( emailTemplate.id, $helpers.isTrue( emailTemplate._version_is_draft ) );
			}
		} while ( emailTemplate.recordCount );
	}

	public void function regenerateSummaryData( required string templateId ) {
		_migrateTemplateToSummaryTables( arguments.templateId );
	}

	public query function getLinkClickReport( required string templateId ) {
		return $getPresideObject( "email_template_click_stats" ).selectData(
			  filter       = { template=arguments.templateId }
			, selectFields = [ "sum( click_count ) as clicks", "link_hash", "link", "link_title", "link_body" ]
			, groupBy      = "link_hash"
			, orderBy      = "clicks desc"
		);
	}

// PRIVATE HELPERS
	private void function _resetTmpExtensionMigration() {
		var migration = $getPresideObject( "db_migration_history" ).selectData(
			filter={ migration_key="EmailLogPerformanceMigrateToSummaryTables-async" }
		);

		if ( migration.recordCount ) {
			$systemOutput( "[EmailLogPerformance] Resetting previous migration from temporary performance extension..." );
			templateDao.updateData( filter={ _version_is_draft=false }, data={
				  stats_collection_enabled    = false
				, stats_collection_enabled_on = ""
			} );

			$getPresideObject( "db_migration_history" ).deleteData(
				filter={ migration_key="EmailLogPerformanceMigrateToSummaryTables-async" }
			);
			$systemOutput( "[EmailLogPerformance] Finished resetting previous migration from temporary performance extension. All templates will now be migrated from scratch." );
		}
	}

	private string function _getDsn() {
		if ( !StructKeyExists( variables, "_dsn" ) ) {
			variables._dsn = $getPresideObject( "email_template_stats" ).getDsn();
		}

		return variables._dsn;
	}

	private string function _getRecordHitSql( hitStat ) {
		var po        = $getPresideObject( "email_template_stats" );
		var dbAdapter = po.getDbAdapter();

		if ( !StructKeyExists( variables, "_recordHitSql" ) ) {
			var tableName        = dbAdapter.escapeEntity( po.getTableName() );
			var hourStart        = dbAdapter.escapeEntity( "hour_start"         );
			var template         = dbAdapter.escapeEntity( "template"           );
			var sendCount        = dbAdapter.escapeEntity( "send_count"         );
			var deliveryCount    = dbAdapter.escapeEntity( "delivery_count"     );
			var openCount        = dbAdapter.escapeEntity( "open_count"         );
			var uniqueOpenCount  = dbAdapter.escapeEntity( "unique_open_count"  );
			var botOpenCount     = dbAdapter.escapeEntity( "bot_open_count"     );
			var clickCount       = dbAdapter.escapeEntity( "click_count"        );
			var uniqueClickCount = dbAdapter.escapeEntity( "unique_click_count" );
			var botClickCount    = dbAdapter.escapeEntity( "bot_click_count" )  ;
			var failCount        = dbAdapter.escapeEntity( "fail_count"         );
			var spamCount        = dbAdapter.escapeEntity( "spam_count"         );
			var unsubscribeCount = dbAdapter.escapeEntity( "unsubscribe_count"  );

			variables._dbadapterName = ListLast( GetMetaData( dbAdapter ).name, "." );

			if ( variables._dbadapterName == "MySqlAdapter" ) {
				variables._recordHitSql =
					"insert into #tableName# (#hourStart#, #template#, #sendCount#, #deliveryCount#, #openCount#, #uniqueOpenCount#, #botOpenCount#, #clickCount#, #uniqueClickCount#, #botClickCount#, #failCount#, #spamCount#, #unsubscribeCount#) " &
					"values ( :hour_start, :template, :send_count, :delivery_count, :open_count, :unique_open_count, :bot_open_count, :click_count, :unique_click_count, :bot_click_count, :fail_count, :spam_count, :unsubscribe_count ) " &
					"on duplicate key update {{hit_stat}} = {{hit_stat}} + :{{hit_stat_param}}";

			} else {
				variables._recordHitSql = "";
			}
		}

		if ( !Len( variables._recordHitSql ) ) {
			throw( type="email.log.performance.unsupported.db", message="The #variables._dbadapterName# db adapter is not currently supported by the email log performance extension." );
		}

		var sql = Replace( variables._recordHitSql, "{{hit_stat}}", dbAdapter.escapeEntity( "#arguments.hitStat#_count" ), "all" )
		    sql = Replace( sql, "{{hit_stat_param}}", "#arguments.hitStat#_count", "all" );

		return sql;
	}

	private string function _getRecordClickSql( hitStat ) {
		var po        = $getPresideObject( "email_template_click_stats" );
		var dbAdapter = po.getDbAdapter();

		if ( !StructKeyExists( variables, "_recordClickSql" ) ) {
			var tableName  = dbAdapter.escapeEntity( po.getTableName() );
			var hourStart  = dbAdapter.escapeEntity( "hour_start"      );
			var template   = dbAdapter.escapeEntity( "template"    );
			var link       = dbAdapter.escapeEntity( "link"        );
			var linkBody   = dbAdapter.escapeEntity( "link_body"   );
			var linkTitle  = dbAdapter.escapeEntity( "link_title"  );
			var linkHash   = dbAdapter.escapeEntity( "link_hash"   );
			var clickCount = dbAdapter.escapeEntity( "click_count" );

			variables._dbadapterName = ListLast( GetMetaData( dbAdapter ).name, "." );

			if ( variables._dbadapterName == "MySqlAdapter" ) {

				variables._recordClickSql =
					"insert into #tableName# (#template#, #hourStart#, #link#, #linkBody#, #linkTitle#, #linkHash#, #clickCount# ) " &
					"values ( :template, :hour_start, :link, :link_body, :link_title, :link_hash, :click_count ) " &
					"on duplicate key update #clickCount# = #clickCount# + :click_count";

			} else {
				variables._recordClickSql = "";
			}
		}

		if ( !Len( variables._recordClickSql ) ) {
			throw( type="email.log.performance.unsupported.db", message="The #variables._dbadapterName# db adapter is not currently supported by the email log performance extension." );
		}

		return variables._recordClickSql;
	}

	private function _prepareHitRecordParams( emailTemplateId, hitDate, hitStat, hitCount ) {
		return [
			  { name="hour_start"        , type="cf_sql_integer", value=_getHourStart( arguments.hitDate ) }
			, { name="template"          , type="cf_sql_varchar", value=arguments.emailTemplateId }
			, { name="send_count"        , type="cf_sql_integer", value=arguments.hitStat == "send"         ? arguments.hitCount : 0 }
			, { name="delivery_count"    , type="cf_sql_integer", value=arguments.hitStat == "delivery"     ? arguments.hitCount : 0 }
			, { name="open_count"        , type="cf_sql_integer", value=arguments.hitStat == "open"         ? arguments.hitCount : 0 }
			, { name="unique_open_count" , type="cf_sql_integer", value=arguments.hitStat == "unique_open"  ? arguments.hitCount : 0 }
			, { name="bot_open_count"    , type="cf_sql_integer", value=arguments.hitStat == "bot_open"     ? arguments.hitCount : 0 }
			, { name="click_count"       , type="cf_sql_integer", value=arguments.hitStat == "click"        ? arguments.hitCount : 0 }
			, { name="unique_click_count", type="cf_sql_integer", value=arguments.hitStat == "unique_click" ? arguments.hitCount : 0 }
			, { name="bot_click_count"   , type="cf_sql_integer", value=arguments.hitStat == "bot_click"    ? arguments.hitCount : 0 }
			, { name="fail_count"        , type="cf_sql_integer", value=arguments.hitStat == "fail"         ? arguments.hitCount : 0 }
			, { name="spam_count"        , type="cf_sql_integer", value=arguments.hitStat == "spam"         ? arguments.hitCount : 0 }
			, { name="unsubscribe_count" , type="cf_sql_integer", value=arguments.hitStat == "unsubscribe"  ? arguments.hitCount : 0 }
		];
	}

	private function _prepareClickRecordParams( emailTemplateId, hitDate, link, link_body, link_title, clickCount ) {
		var linkHash = Hash( arguments.link & "-" & arguments.link_body & "-" & arguments.link_title );

		return [
			  { name="hour_start" , type="cf_sql_integer", value=_getHourStart( arguments.hitDate ) }
			, { name="template"   , type="cf_sql_varchar", value=arguments.emailTemplateId }
			, { name="link"       , type="cf_sql_varchar", value=arguments.link            }
			, { name="link_body"  , type="cf_sql_varchar", value=arguments.link_body       }
			, { name="link_title" , type="cf_sql_varchar", value=arguments.link_title      }
			, { name="link_hash"  , type="cf_sql_varchar", value=linkHash                  }
			, { name="click_count", type="cf_sql_integer", value=arguments.clickCount      }
		];
	}

	private function _getHourStart( hitDate ) {
		return DateDiff( "h", "1970-01-01 00:00:00", arguments.hitDate );
	}

	private function _migrateTemplateToSummaryTables( templateId, isDraft=false ) {
		var startms = GetTickCount();

		$systemOutput( "[EmailLogPerformance] Migrating email template with id [#arguments.templateId#] to summary tables for statistics..." );

		statsSummaryDao.deleteData( filter={ template=arguments.templateId }, skipTrivialInterceptors=true ); // in case of failed previous attempts or regeneration

		var turnedOnDate = Now();
		var dateFilter   = { filter="email_template_send_log_activity.datecreated <= :datecreated", filterParams={ datecreated=turnedOnDate } };

		templateDao.updateData( id=arguments.templateId, isDraft=arguments.isDraft, data={
			  stats_collection_enabled    = true
			, stats_collection_enabled_on = turnedOnDate
		} );

		var activityTypes = {
			  send        = "send"
			, deliver     = "delivery"
			, fail        = "fail"
			, open        = "open"
			, click       = "click"
			, markAsSpam  = "spam"
			, unsubscribe = "unsubscribe"
		};

		for( var at in activityTypes ) {
			var summaries = activityDao.selectData(
				  selectFields = [ "count(*) as n", "floor( unix_timestamp( email_template_send_log_activity.datecreated ) / 3600 ) as hour_start" ]
				, filter       = { "message.email_template"=arguments.templateId, activity_type=at }
				, extraFilters = [ dateFilter ]
				, groupBy      = "hour_start"
				, timeout      = 0
			);

			for ( var s in summaries ) {
				recordHit(
					  emailTemplateId = arguments.templateId
					, hitStat         = activityTypes[ at ]
					, hitDate         = DateAdd( "h", s.hour_start, "1970-01-01" )
					, hitCount        = s.n
				);
			}
		}

		var uniques = [ "open", "click" ];

		for( var u in uniques ) {
			var uniqueSubquery = activityDao.selectData(
				  selectFields        = [ "message", "min( email_template_send_log_activity.datecreated ) as first_instance" ]
				, filter              = { activity_type=u, "message.email_template"=arguments.templateId }
				, groupBy             = "message"
				, getSqlAndParamsOnly = true
			);
			var summaries = sqlRunner.runSql(
				  dsn    = activityDao.getDsn()
				, sql    = "select count( sub.message ) as n, floor( unix_timestamp( sub.first_instance ) / 3600 ) as hour_start from ( #uniqueSubquery.sql# ) sub group by hour_start"
				, params = uniqueSubquery.params
			);
			for ( var s in summaries ) {
				recordHit(
					  emailTemplateId = arguments.templateId
					, hitStat         = "unique_#u#"
					, hitDate         = DateAdd( "h", s.hour_start, "1970-01-01" )
					, hitCount        = s.n
				);
			}
		}

		var clicks = activityDao.selectData(
			  selectFields = [ "count(*) as n", "floor( unix_timestamp( email_template_send_log_activity.datecreated ) / 3600 ) as hour_start", "link", "link_body", "link_title" ]
			, filter       = { activity_type="click", "message.email_template"=arguments.templateId }
			, extraFilters = [ dateFilter ]
			, groupBy      = "hour_start,link,link_body,link_title"
			, timeout      = 0
		);
		for( var c in clicks ) {
			_recordClick(
				  emailTemplateId = arguments.templateId
				, hitDate         = DateAdd( "h", c.hour_start, "1970-01-01" )
				, link            = c.link
				, link_body       = c.link_body
				, link_title      = c.link_title
				, clickCount      = c.n
			);
		}

		sqlrunner.runSql(
			  dsn = activityDao.getDsn()
			, sql = "update psys_email_template_send_log as l inner join ( select count(1) as n, message from psys_email_template_send_log_activity where activity_type = :activity_type group by message ) as sub on sub.message = l.id set l.open_count = sub.n where l.email_template = :email_template"
			, params = [ { name="email_template", type="cf_sql_varchar", value=arguments.templateId }, { name="activity_type", type="cf_sql_varchar", value="open" } ]
		);

		$systemOutput( "[EmailLogPerformance] Finished migrating email template with id [#arguments.templateId#] in #NumberFormat( GetTickCount()-startms )#ms" );
	}

	private function _getEmailLogPerformanceDateFilters( dateFrom, dateTo ) {
		var extraFilters = [];
		if ( IsDate( arguments.dateFrom ) ) {
			ArrayAppend( extraFilters, {
				  filter = "hour_start >= :dateFrom"
				, filterParams = { dateFrom={ type="cf_sql_integer", value=_epochInHours( arguments.dateFrom ) } }
			});
		}
		if ( IsDate( arguments.dateTo ) ) {
			ArrayAppend( extraFilters, {
				  filter       = "hour_start <= :dateTo"
				, filterParams = { dateTo={ type="cf_sql_integer", value=_epochInHours( arguments.dateTo ) } }
			});
		}

		return extraFilters;
	}
	private function _epochInHours( someDate ) {
		return DateDiff( 'h', '1970-01-01 00:00:00', arguments.someDate );
	}

	private string function _validateStatField( field ) {
		var validFields = [
			  "send_count"
			, "delivery_count"
			, "open_count"
			, "unique_open_count"
			, "click_count"
			, "unique_click_count"
			, "fail_count"
			, "spam_count"
			, "unsubscribe_count"
			, "bot_open_count"
			, "bot_click_count"
		];

		if ( ArrayFind( validFields, arguments.field ) ) {
			return arguments.field;
		}

		throw( type="email.logging.invalid.stat.field", message="The statistics field, [#arguments.field#], is not a valid field to get a hit count for." );
	}

}