component hint="Interact with and report on system caches" {

	property name="jsonRpc2Plugin"       inject="JsonRpc2";
	property name="cachebox"             inject="cachebox";
	property name="presideObjectService" inject="presideObjectService";

	private function index( event, rc, prc ) {
		var params       = jsonRpc2Plugin.getRequestParams();
		var validOperations = [ "stats", "resetstats" ];

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !params.len() || !ArrayFindNoCase( validOperations, params[1] ) ) {
			return Chr(10) & "[[b;white;]Usage:] cache [operation]" & Chr(10) & Chr(10)
			               & "Valid operations:" & Chr(10) & Chr(10)
			               & "    [[b;white;]stats]      : Displays summary statistics of the Preside caches." & Chr(10)
			               & "    [[b;white;]resetstats] : Resets hit, miss and other agreggated statistics to zero." & Chr(10)
		}

		return runEvent( event="admin.devtools.terminalCommands.cache.#params[1]#", private=true, prePostExempt=true );
	}

	private function stats( event, rc, prc ) {
		var params           = jsonRpc2Plugin.getRequestParams();
		var full             = ( params.commandLineArgs[ 2 ] ?: "" ) == "full"
		var cacheName        = params[ 2 ] ?: "";
		var cachesToShow     = cacheName.listToArray( Trim( cacheName ) );
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
		var doSpecialQueryCache = !full && isFeatureEnabled( "queryCachePerObject" ) && !cacheName.listToArray( Trim( cacheName ) ).len();

		if ( !cachesToShow.len() ) {
			cachesToShow = cachebox.getCacheNames();
			if ( doSpecialQueryCache ) {
				for( var i=cachesToShow.len(); i>0; i-- ) {
					if ( cachesToShow[ i ] == "DefaultQueryCache" || cachesToShow[ i ].reFindNoCase( "^presideQueryCache_.+" ) ) {
						cachesToShow.deleteAt( i );
					}
				}

				cachesToShow.append( "_special_query_cache_" );
			}
		}

		for( var cacheName in cachesToShow ){
			if ( cacheName == "_special_query_cache_" || cachebox.cacheExists( cacheName ) ) {
				if ( cacheName == "_special_query_cache_" ) {
					var cacheStat = { name="Query cache" };

					cacheStat.append( presideObjectService.getCacheStats() );

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

				cacheStats.append( cacheStat );

				titleWidth       = cacheName.len()             > titleWidth       ? cacheName.len()             : titleWidth;
				objectsWidth     = cacheStat.objects.len()     > objectsWidth     ? cacheStat.objects.len()     : objectsWidth;
				hitsWidth        = cacheStat.hits.len()        > hitsWidth        ? cacheStat.hits.len()        : hitsWidth;
				missesWidth      = cacheStat.misses.len()      > missesWidth      ? cacheStat.misses.len()      : missesWidth;
				evictionsWidth   = cacheStat.evictions.len()   > evictionsWidth   ? cacheStat.evictions.len()   : evictionsWidth;
				performanceWidth = cacheStat.performance.len() > performanceWidth ? cacheStat.performance.len() : performanceWidth;
				gcsWidth         = cacheStat.gcs.len()         > gcsWidth         ? cacheStat.gcs.len()         : gcsWidth;
				lastReapWidth    = cacheStat.lastReap.len()    > lastReapWidth    ? cacheStat.lastReap.len()    : lastReapWidth;
			}
		}

		if ( !cacheStats.len() ) {
			return "[[b;white;]There are no caches that match your query!]" & Chr(10);
		}

		var titleBar = " [[b;white;]Name] #RepeatString( ' ', titleWidth-4 )# "
					 & " [[b;white;]Objects] #RepeatString( ' ', objectsWidth-7 )# "
					 & " [[b;white;]Hits] #RepeatString( ' ', hitsWidth-4 )# "
					 & " [[b;white;]Misses] #RepeatString( ' ', missesWidth-6 )# "
					 & " [[b;white;]Evictions] #RepeatString( ' ', evictionsWidth-9 )# "
					 & " [[b;white;]Performance ratio] #RepeatString( ' ', performanceWidth-17 )# "
					 & " [[b;white;]Garbage collections] #RepeatString( ' ', gcsWidth-19 )# "
					 & " [[b;white;]Last reap] #RepeatString( ' ', lastReapWidth-9 )#";

		var tableWidth = titleBar.len() - 96;

		statsOutput = Chr( 10 ) & titleBar & Chr( 10 ) & RepeatString( "=", tableWidth ) & Chr(10);

		for( var cache in cacheStats ){
			statsOutput &= " [[b;white;]#cache.name#] #RepeatString( ' ', titleWidth-cache.name.len() )# "
			             & " #cache.objects# #RepeatString( ' ', objectsWidth-cache.objects.len() )# "
			             & " #cache.hits# #RepeatString( ' ', hitsWidth-cache.hits.len() )# "
			             & " #cache.misses# #RepeatString( ' ', missesWidth-cache.misses.len() )# "
			             & " #cache.evictions# #RepeatString( ' ', evictionsWidth-cache.evictions.len() )# "
			             & " #cache.performance# #RepeatString( ' ', performanceWidth-cache.performance.len() )# "
			             & " #cache.gcs# #RepeatString( ' ', gcsWidth-cache.gcs.len() )# "
			             & " #cache.lastReap# #RepeatString( ' ', lastReapWidth-cache.lastReap.len() )#" & Chr( 10 );

			statsOutput &= RepeatString( "-", tableWidth ) & Chr(10);
		}

		return statsOutput;
	}

	private function resetstats( event, rc, prc ) {
		var params        = jsonRpc2Plugin.getRequestParams();
		var cacheName     = params[ 2 ] ?: "";
		var cachesToClear = cacheName.listToArray( Trim( cacheName ) );

		if ( !cachesToClear.len() ) {
			cachesToClear = cachebox.getCacheNames();
		}

		for( var cacheName in cachesToClear ){
			if ( cachebox.cacheExists( cacheName ) ) {
				cachebox.getCache( cacheName ).getStats().clearStatistics();
			}
		}

		return runEvent( event="admin.devtools.terminalCommands.cache.stats", private=true, prePostExempt=true );
	}

}