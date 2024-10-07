/**
 *
 * @presideService true
 * @singleton      true
 * @feature        admin
 */
component {

	variables._MINUTE = 60;
	variables._HOUR   = variables._MINUTE * 60;
	variables._DAY    = variables._HOUR * 24;
	variables._WEEK   = variables._DAY * 7;
	variables._MONTH  = variables._WEEK * 4;
	variables._YEAR   = variables._WEEK * 52;

	property name="sqlRunner" inject="sqlRunner";
	property name="dsn"       inject="coldbox:setting:dsn";

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public any function getTimeSeriesData(
		  required string  sourceObject
		, required date    startDate
		, required date    endDate
		,          string  minResolution     = "s"
		,          struct  timeResolution    = calculateTimeResolution( arguments.startDate, arguments.endDate, arguments.epochResolution )
		,          array   expectedTimes     = getExpectedTimes( timeResolution, arguments.startDate, arguments.endDate )
		,          string  groupBy           = ""
		,          string  secondaryGroupBy  = ""
		,          string  aggregateFunction = "count"
		,          string  aggregateOver     = "1"
		,          string  timeField         = "datecreated"
		,          string  decimalPrecision  = ""
		,          array   extraFilters      = []
		,          boolean valuesOnly        = false
		,          boolean timeFieldIsEpoch  = false
		,          string  epochResolution   = "s"
	) {
		var fullTimeSeries = { labels=[], datasets=[] };

		if ( !Len( Trim( arguments.timeField ) ) ) {
			arguments.timeField = $getPresideObjectService().getDateCreatedField( arguments.sourceObject );
		}

		var timeValue      = _calculateTimeValue( argumentCollection=arguments );
		var aggOver        = arguments.aggregateFunction == "count" ? "1" : arguments.aggregateOver;
		var valueField     = "";
		var mapped         = StructNew( "linked" );
		var groupedValues  = {};
		var grouped        = Len( Trim( arguments.groupBy ) ) > 0;
		var timeFieldType  = arguments.timeFieldIsEpoch ? "cf_sql_integer" : "cf_sql_timestamp";
		var start          = arguments.timeFieldIsEpoch ? _epochTime( arguments.startDate, arguments.epochResolution ) : arguments.startDate;
		var end            = arguments.timeFieldIsEpoch ? _epochTime( arguments.endDate  , arguments.epochResolution ) : arguments.endDate;
		var selectDataArgs = {
			  selectFields = [ timeValue ]
			, filter       = "#timeField# >= :start and #timeField# <= :end"
			, filterParams = { start={ type=timeFieldType, value=start }, end={ type=timeFieldType, value=end } }
			, groupBy      = "_time"
			, orderBy      = "_time"
			, extraFilters = Duplicate( arguments.extraFilters )
		};

		ArrayAppend( selectDataArgs.selectFields, "#arguments.aggregateFunction#( #aggOver# ) as _value" );
		if ( grouped ) {
			ArrayAppend( selectDataArgs.selectFields, arguments.groupBy & " as _groupval" );
			selectDataArgs.groupBy &= ", _groupval";

			if ( Len( Trim( arguments.secondaryGroupBy ) ) ) {
				ArrayAppend( selectDataArgs.selectFields, arguments.secondaryGroupBy & " as _groupval2" );
				selectDataArgs.groupBy &= ", _groupval, _groupval2";
			}
		} else {
			ArrayAppend( fullTimeSeries.datasets, { label="_", values=[] } );
		}

		var rawResults = $getPresideObject( arguments.sourceObject ).selectData( argumentCollection=selectDataArgs );

		for( var result in rawResults ) {
			if ( grouped ) {
				mapped[ result._time ] = mapped[ result._time ] ?: {};
				var groupVal = result._groupval;
				if ( Len( Trim( arguments.secondaryGroupBy ) ) ) {
					groupVal &= "|" & result._groupval2;
				}

				groupedValues[ groupval ] = true;
				mapped[ result._time ][ groupval ] = applyPrecision( result._value, arguments.decimalPrecision );
			} else {
				mapped[ result._time ] = applyPrecision( result._value, arguments.decimalPrecision );
			}
		}

		if ( grouped ) {
			for( var groupId in groupedValues ) {
				var groupLabel = arguments.renderGroupLabels ? renderGroupByLabel( arguments.sourceObject, arguments.groupBy, ListFirst( groupId, "|" ) ) : ListFirst( groupId, "|" );

				if ( Len( Trim( arguments.secondaryGroupBy ) ) ) {
					groupLabel &= " / " & ( arguments.renderGroupLabels ? renderGroupByLabel( arguments.sourceObject, arguments.secondaryGroupBy, ListRest( groupId, "|" ) ) : ListRest( groupId, "|" ) );
				}
				ArrayAppend( fullTimeSeries.datasets, { label=groupLabel, values=[] } );
			}
		}

		for( var t in arguments.expectedTimes ) {
			if ( !arguments.valuesOnly && !ArrayFind( fullTimeSeries.labels, t ) ) {
				ArrayAppend( fullTimeSeries.labels, t );
			}

			if ( grouped ) {
				var n = 0;
				for( var groupId in groupedValues ) {
					ArrayAppend( fullTimeSeries.datasets[ ++n ].values, mapped[ t ][ groupId ] ?: 0 );
				}
			} else {
				ArrayAppend( fullTimeSeries.datasets[ 1 ].values, mapped[ t ] ?: 0 );
			}
		}

		if ( arguments.valuesOnly ) {
			return fullTimeSeries.datasets[ 1 ].values;
		}

		return fullTimeSeries;
	}

	public struct function calculateTimeResolution( startDate, endDate, resolution="s" ) {
		var daysDiff  = DateDiff( 'd', arguments.startDate, arguments.endDate );
		var hoursDiff = DateDiff( 'h', arguments.startDate, arguments.endDate );
		var minsDiff  = DateDiff( 'n', arguments.startDate, arguments.endDate );

		if ( daysDiff >= 300 ) {
			return { seconds=variables._MONTH, hourStep=24, minStep=60 };
		}

		if ( daysDiff >= 90 ) {
			return { seconds=variables._WEEK, hourStep=24, minStep=60 };
		}

		if ( daysDiff >= 30 ) {
			return { seconds=variables._DAY * 2, hourStep=24, minStep=60 };
		}

		if ( daysDiff > 7 || arguments.resolution == "d" ) {
			return { seconds=variables._DAY, hourStep=24, minStep=60 };
		}

		if ( daysDiff > 3 ) {
			return { seconds=variables._HOUR * 12, hourStep=12, minStep=60 };
		}

		if ( daysDiff > 1 ) {
			return { seconds=variables._HOUR * 8, hourStep=8, minStep=60 };
		}

		if ( hoursDiff > 20 ) {
			return { seconds=variables._HOUR * 2, hourStep=2, minStep=60 };
		}

		if ( hoursDiff > 10 || arguments.resolution == "h") {
			return { seconds=variables._HOUR, hourStep=1, minStep=60 };
		}

		if ( hoursDiff > 5 ) {
			return { seconds=variables._HOUR / 2, hourStep=1, minStep=30 };
		}

		if ( hoursDiff > 2 ) {
			return { seconds=variables._HOUR / 3, hourStep=1, minStep=20 };
		}

		if ( minsDiff > 80 ) {
			return { seconds=variables._MINUTE * 10, hourStep=1, minStep=10 };
		}

		if ( minsDiff > 40 ) {
			return { seconds=variables._MINUTE * 5, hourStep=1, minStep=5 };
		}

		if ( minsDiff > 20 ) {
			return { seconds=variables._MINUTE * 2, hourStep=1, minStep=2 };
		}

		return { seconds=variables._MINUTE, hourStep=1, minStep=60 };
	}

	public array function getExpectedTimes( resolution, startDate, endDate ) {
		var daysDiff  = DateDiff( "d", arguments.startDate, arguments.endDate );
		var hoursDiff = DateDiff( "h", arguments.startDate, arguments.endDate );
		var minsDiff  = DateDiff( "n", arguments.startDate, arguments.endDate );

		var sql = "
			select
				distinct from_unixtime( floor( UNIX_TIMESTAMP( generated_date ) / ? ) * ? ) as expected_date
			from (
				select
					addtime( adddate( from_unixtime( floor( UNIX_TIMESTAMP( ? ) / ? ) * ? ), t4*10000 + t3*1000 + t2*100 + t1*10 + t0 ), hrs*10000 + mins*100 ) generated_date
				from
					#sqlTempDataRange( "t0", 0, daysDiff > 10 ? 9 : daysDiff )#,
					#sqlTempDataRange( "t1", 0, daysDiff > 100 ? 9 : daysDiff \ 10 )#,
					#sqlTempDataRange( "t2", 0, daysDiff > 1000 ? 9 : daysDiff \ 100 )#,
					#sqlTempDataRange( "t3", 0, daysDiff > 10000 ? 9 : daysDiff \ 1000 )#,
					#sqlTempDataRange( "t4", 0, daysDiff \ 10000 )#,
					#sqlTempDataRange( "hrs", 0, 23, arguments.resolution.hourStep )#,
					#sqlTempDataRange( "mins", 0, 59, arguments.resolution.minStep )#
			) v
			where
				generated_date between from_unixtime( floor( UNIX_TIMESTAMP( ? ) / ? ) * ? ) and ?
			order by
				generated_date";

		var params = [
			  { type="integer"  , value=arguments.resolution.seconds }
			, { type="integer"  , value=arguments.resolution.seconds }
			, { type="timestamp", value=arguments.startDate }
			, { type="integer"  , value=arguments.resolution.seconds }
			, { type="integer"  , value=arguments.resolution.seconds }
			, { type="timestamp", value=arguments.startDate }
			, { type="integer"  , value=arguments.resolution.seconds }
			, { type="integer"  , value=arguments.resolution.seconds }
			, { type="timestamp", value=arguments.endDate }
		];

		var expectedTimes = sqlRunner.runSql( sql=sql, dsn=dsn, params=params );

		return ValueArray( expectedTimes, "expected_date" );
	}

	public string function sqlTempDataRange( required string alias, numeric from=0, numeric to=0, numeric step=1 ) {
		var data = [];
		for( var i=arguments.from; i<=arguments.to; i+=arguments.step ) {
			ArrayAppend( data, "select #i# as #arguments.alias#" );
		}
		return "( " & ArrayToList( data, " union " ) & " ) #arguments.alias#";
	}

	public string function renderGroupByLabel( sourceObject, fieldName, value ) {
		var objProps = $getPresideObjectService().getObjectProperties( arguments.sourceObject );
		if ( !StructKeyExists( objProps, arguments.fieldname ) ) {
			return arguments.value;
		}

		var rendered = "";
		var relatedTo = objProps[ arguments.fieldname ].relatedTo ?: "none";
		if ( relatedTo != "none" &&  $getPresideObjectService().objectExists( relatedTo ) ) {
			rendered = $renderLabel( objProps[ arguments.fieldname ].relatedTo, arguments.value );
		} else {
			rendered = $renderField(
				  object   = arguments.sourceObject
				, property = arguments.fieldName
				, data     = arguments.value
				, context  = [ "datavizMetric", "adminView", "admin" ]
			);
		}
		rendered = $helpers.stripTags( rendered );
		rendered = ReReplaceNoCase( rendered, "\&[a-z]+;", "", "all" );

		return Trim( rendered );
	}

	public string function applyPrecision( required numeric value, required string precision ) {
		if ( IsNumeric( arguments.precision ) ) {
			if ( arguments.precision > 0 ) {
				return NumberFormat( arguments.value, "_.#RepeatString( "0", arguments.precision )#" );
			} else {
				return Round( arguments.value );
			}
		}

		return arguments.value;
	}

// helpers
	private string function _calculateTimeValue( timefield, timeResolution, timeFieldIsEpoch, epochResolution ) {
		if ( !arguments.timeFieldIsEpoch ) {
			return  "from_unixtime(floor(UNIX_TIMESTAMP(#arguments.timeField#)/#timeResolution.seconds#)*#timeResolution.seconds#) as _time";
		}

		var divider    = arguments.timeResolution.seconds;
		var multiplier = divider;

		switch( arguments.epochResolution ) {
			case "d":
				divider = arguments.timeResolution.seconds / 60 / 60 / 24;
				multiplier = divider * ( 60 * 60 * 24 );
			break;
			case "h":
				divider = arguments.timeResolution.seconds / 60 / 60;
				multiplier = divider * ( 60 * 60 );
			break;
			case "n":
				divider = arguments.timeResolution.seconds / 60;
				multiplier = divider * ( 60 );
			break;
			case "s":
				divider = arguments.timeResolution.seconds;
				multiplier = divider;
			break;
		}

		return "from_unixtime( floor( #arguments.timeField# / #divider# ) * #multiplier# ) as _time"
	}

	private numeric function _epochTime( adate, resolution ) {
		return DateDiff( arguments.resolution, "1970-01-01 00:00:00", arguments.adate );
	}
}