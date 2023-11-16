component hint="Interact with and report on system caches" extends="preside.system.base.Command" {

	property name="jsonRpc2Plugin"       inject="JsonRpc2";
	property name="cachebox"             inject="cachebox";
	property name="presideObjectService" inject="presideObjectService";

	private function index( event, rc, prc ) {
		var params          = jsonRpc2Plugin.getRequestParams();
		var validOperations = [ "stats", "resetstats", "clear" ];

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !ArrayLen( params ) || !ArrayFindNoCase( validOperations, params[1] ) ) {
			var message = newLine();

			message &= writeText( text="Usage: ", type="help", bold=true );
			message &= writeText( text="cache <operation>", type="help", newline=2 );

			message &= writeText( text="Valid operations:", type="help", newline=2 );

			message &= writeText( text="    stats            ", type="help", bold=true );
			message &= writeText( text=" : Displays summary statistics of the Preside caches", type="help", newline=true );

			message &= writeText( text="    resetstats       ", type="help", bold=true );
			message &= writeText( text=" : Resets hit, miss and other agreggated statistics to zero", type="help", newline=true );

			message &= writeText( text="    clear <cachename>", type="help", bold=true );
			message &= writeText( text=" : Clears the specified cache or caches", type="help", newline=true );

			return message;
		}

		return runEvent( event="admin.devtools.terminalCommands.cache.#params[1]#", private=true, prePostExempt=true );
	}

	private function stats( event, rc, prc ) {
		var params           = jsonRpc2Plugin.getRequestParams();
		var full             = ( params.commandLineArgs[ 2 ] ?: "" ) == "full"
		var cacheNames       = full ? "" : ( params.commandLineArgs[ 2 ] ?: "" );
		var cachesToShow     = ListToArray( Trim( cacheNames ) );
		var cacheStats       = [];
		var statsOutput      = "";
		var titleWidth       = 4;
		var objectsWidth     = 7;
		var hitsWidth        = 4;
		var missesWidth      = 6;
		var evictionsWidth   = 9;
		var performanceWidth = 17;
		var gcsWidth         = 19;
		var lastReapWidth    = 9;
		var doSpecialQueryCache = !full && isFeatureEnabled( "queryCachePerObject" ) && !ArrayLen( cachesToShow );

		if ( !ArrayLen( cachesToShow ) ) {
			cachesToShow = cachebox.getCacheNames();
			if ( doSpecialQueryCache ) {
				for( var i=ArrayLen( cachesToShow ); i>0; i-- ) {
					if ( cachesToShow[ i ] == "DefaultQueryCache" || cachesToShow[ i ].reFindNoCase( "^presideQueryCache_.+" ) ) {
						ArrayDeleteAt( cachesToShow, i );
					}
				}

				ArrayAppend( cachesToShow, "_special_query_cache_" );
			}
		}

		for( var cacheName in cachesToShow ){
			if ( cacheName == "_special_query_cache_" || cachebox.cacheExists( cacheName ) ) {
				if ( cacheName == "_special_query_cache_" ) {
					var cacheStat = { name="Query cache" };

					StructAppend( cacheStat, presideObjectService.getCacheStats() );

					cacheStat.objects     = NumberFormat( cacheStat.objects ) & " / " & NumberFormat( cacheStat.maxObjects );
					cacheStat.hits        = NumberFormat( cacheStat.hits );
					cacheStat.misses      = NumberFormat( cacheStat.misses );
					cacheStat.evictions   = NumberFormat( cacheStat.evictions );
					cacheStat.performance = NumberFormat( cacheStat.performance, "0.00" );
					cacheStat.gcs         = NumberFormat( cacheStat.gcs );
					cacheStat.lastReap    = DateTimeFormat( cacheStat.lastReap, "yyyy-mm-dd HH:mm:ss" );
				} else {
					var cacheStat = { name=cacheName };
					var cache     = cachebox.getCache( cacheName );
					var config    = cache.getMemento().configuration;
					var stats     = cache.getStats();

					cacheStat.objects     = NumberFormat( stats.getObjectCount() ) & "/" & NumberFormat( config.maxObjects ?: 200 );
					cacheStat.hits        = NumberFormat( stats.getHits() );
					cacheStat.misses      = NumberFormat( stats.getMisses() );
					cacheStat.evictions   = NumberFormat( stats.getEvictionCount() );
					cacheStat.performance = NumberFormat( stats.getCachePerformanceRatio(), "0.00" );
					cacheStat.gcs         = NumberFormat( stats.getGarbageCollections() );
					cacheStat.lastReap    = DateTimeFormat( stats.getLastReapDateTime(), "yyyy-mm-dd HH:mm:ss" );
				}

				ArrayAppend( cacheStats, cacheStat );

				titleWidth       = Len( cacheName )             > titleWidth       ? Len( cacheName )             : titleWidth;
				objectsWidth     = Len( cacheStat.objects )     > objectsWidth     ? Len( cacheStat.objects )     : objectsWidth;
				hitsWidth        = Len( cacheStat.hits )        > hitsWidth        ? Len( cacheStat.hits )        : hitsWidth;
				missesWidth      = Len( cacheStat.misses )      > missesWidth      ? Len( cacheStat.misses )      : missesWidth;
				evictionsWidth   = Len( cacheStat.evictions )   > evictionsWidth   ? Len( cacheStat.evictions )   : evictionsWidth;
				performanceWidth = Len( cacheStat.performance ) > performanceWidth ? Len( cacheStat.performance ) : performanceWidth;
				gcsWidth         = Len( cacheStat.gcs )         > gcsWidth         ? Len( cacheStat.gcs )         : gcsWidth;
				lastReapWidth    = Len( cacheStat.lastReap )    > lastReapWidth    ? Len( cacheStat.lastReap )    : lastReapWidth;
			}
		}

		if ( !ArrayLen( cacheStats ) ) {
			return writeText( text="There are no caches that match your query!", type="info", bold=true, newline=true );
		}

		var titleBar = " Name #RepeatString( ' ', titleWidth-4 )# "
			& " Objects #RepeatString( ' ', objectsWidth-7 )# "
			& " Hits #RepeatString( ' ', hitsWidth-4 )# "
			& " Misses #RepeatString( ' ', missesWidth-6 )# "
			& " Evictions #RepeatString( ' ', evictionsWidth-9 )# "
			& " Performance ratio #RepeatString( ' ', performanceWidth-17 )# "
			& " Garbage collections #RepeatString( ' ', gcsWidth-19 )# "
			& " Last reap #RepeatString( ' ', lastReapWidth-9 )#";

		var tableWidth = Len( titleBar );

		statsOutput = newLine() & writeText( type="info", bold=true, text=titleBar, newline=true );
		statsOutput &= writeLine( character="=", length=tableWidth );

		for( var cache in cacheStats ){
			statsOutput &= writeText( text=" #cache.name#", type="info", bold=true )
				& " #RepeatString( ' ', titleWidth-Len( cache.name ) )# "
				& " #cache.objects# #RepeatString( ' ', objectsWidth-Len( cache.objects ) )# "
				& " #cache.hits# #RepeatString( ' ', hitsWidth-Len( cache.hits ) )# "
				& " #cache.misses# #RepeatString( ' ', missesWidth-Len( cache.misses ) )# "
				& " #cache.evictions# #RepeatString( ' ', evictionsWidth-Len( cache.evictions ) )# "
				& " #cache.performance# #RepeatString( ' ', performanceWidth-Len( cache.performance ) )# "
				& " #cache.gcs# #RepeatString( ' ', gcsWidth-Len( cache.gcs ) )# "
				& " #cache.lastReap# #RepeatString( ' ', lastReapWidth-Len( cache.lastReap ) )#" & newLine();

			statsOutput &= writeLine( tableWidth );
		}

		return statsOutput;
	}

	private function resetstats( event, rc, prc ) {
		var params        = jsonRpc2Plugin.getRequestParams();
		var cacheNames    = params.commandLineArgs[ 2 ] ?: "";
		var cachesToClear = ListToArray( Trim( cacheNames ) );

		if ( !ArrayLen( cachesToClear ) ) {
			cachesToClear = cachebox.getCacheNames();
		}

		for( var cacheName in cachesToClear ){
			if ( cachebox.cacheExists( cacheName ) ) {
				cachebox.getCache( cacheName ).getStats().clearStatistics();
			}
		}

		return runEvent( event="admin.devtools.terminalCommands.cache.stats", private=true, prePostExempt=true );
	}

	private function clear( event, rc, prc ) {
		var params        = jsonRpc2Plugin.getRequestParams();
		var cacheNames    = params.commandLineArgs[ 2 ] ?: "";
		var cachesToClear = ListToArray( Trim( cacheNames ) );

		if ( !ArrayLen( cachesToClear ) ) {
			return writeText( text="You must specify the name of a cache to clear]", type="info", bold=true, newline=true );
		}

		for( var cacheName in cachesToClear ){
			if ( cachebox.cacheExists( cacheName ) ) {
				cachebox.getCache( cacheName ).clearAll();
			}
		}

		return runEvent( event="admin.devtools.terminalCommands.cache.stats", private=true, prePostExempt=true );
	}

}