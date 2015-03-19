component output=false hint="Create various preside system entities such as widgets and page types" {

	property name="jsonRpc2Plugin" inject="coldbox:myPlugin:JsonRpc2";
	property name="cachebox"       inject="cachebox";

	private function index( event, rc, prc ) {
		var params       = jsonRpc2Plugin.getRequestParams();
		var validOperations = [ "stats" ];

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !params.len() || !ArrayFindNoCase( validOperations, params[1] ) ) {
			return Chr(10) & "[[b;white;]Usage:] cache [operation]" & Chr(10) & Chr(10)
			               & "Valid operations:" & Chr(10) & Chr(10)
			               & "    [[b;white;]stats] : Displays summary statistics of the PresideCMS caches." & Chr(10)
		}

		return runEvent( event="admin.devtools.terminalCommands.cache.#params[1]#", private=true, prePostExempt=true );
	}

	private function stats( event, rc, prc ) output=false {
		var params           = jsonRpc2Plugin.getRequestParams();
		var cacheName        = params[ 2 ] ?: "";
		var cachesToShow     = cacheName.listToArray( Trim( cacheName ) );
		var cacheStats       = [];
		var statsOutput      = "";
		var titleWidth       = 4;
		var objectsWidth     = 7;
		var hitsWidth        = 4;
		var missesWidth      = 6;
		var performanceWidth = 17;
		var gcsWidth         = 19;
		var lastReapWidth    = 9;

		if ( !cachesToShow.len() ) {
			cachesToShow = cachebox.getCacheNames();
		}

		for( var cacheName in cachesToShow ){
			if ( cachebox.cacheExists( cacheName ) ) {
				var cache = { name=cacheName };
				var stats = cachebox.getCache( cacheName ).getStats();

				cache.objects     = NumberFormat( stats.getObjectCount() );
				cache.hits        = NumberFormat( stats.getHits() );
				cache.misses      = NumberFormat( stats.getMisses() );
				cache.performance = NumberFormat( stats.getCachePerformanceRatio(), "0.00" );
				cache.gcs         = NumberFormat( stats.getGarbageCollections() );
				cache.lastReap    = DateTimeFormat( stats.getLastReapDateTime(), "yyyy-mm-dd HH:mm:ss" );

				cacheStats.append( cache );

				titleWidth       = cacheName.len()         > titleWidth       ? cacheName.len()         : titleWidth;
				objectsWidth     = cache.objects.len()     > objectsWidth     ? cache.objects.len()     : objectsWidth;
				hitsWidth        = cache.hits.len()        > hitsWidth        ? cache.hits.len()        : hitsWidth;
				missesWidth      = cache.misses.len()      > missesWidth      ? cache.misses.len()      : missesWidth;
				performanceWidth = cache.performance.len() > performanceWidth ? cache.performance.len() : performanceWidth;
				gcsWidth         = cache.gcs.len()         > gcsWidth         ? cache.gcs.len()         : gcsWidth;
				lastReapWidth    = cache.lastReap.len()    > lastReapWidth    ? cache.lastReap.len()    : lastReapWidth;
			}
		}

		if ( !cacheStats.len() ) {
			return "[[b;white;]There are no caches that match your query!]" & Chr(10);
		}

		var titleBar = " [[b;white;]Name] #RepeatString( ' ', titleWidth-4 )# "
					 & " [[b;white;]Objects] #RepeatString( ' ', objectsWidth-7 )# "
					 & " [[b;white;]Hits] #RepeatString( ' ', hitsWidth-4 )# "
					 & " [[b;white;]Misses] #RepeatString( ' ', missesWidth-6 )# "
					 & " [[b;white;]Performance ratio] #RepeatString( ' ', performanceWidth-17 )# "
					 & " [[b;white;]Garbage collections] #RepeatString( ' ', gcsWidth-19 )# "
					 & " [[b;white;]Last reap] #RepeatString( ' ', lastReapWidth-9 )#";

		var tableWidth = titleBar.len() - 84;


		statsOutput = Chr( 10 ) & titleBar & Chr( 10 ) & RepeatString( "=", tableWidth ) & Chr(10);

		for( var cache in cacheStats ){
			statsOutput &= " [[b;white;]#cache.name#] #RepeatString( ' ', titleWidth-cache.name.len() )# "
			             & " #cache.objects# #RepeatString( ' ', objectsWidth-cache.objects.len() )# "
			             & " #cache.hits# #RepeatString( ' ', hitsWidth-cache.hits.len() )# "
			             & " #cache.misses# #RepeatString( ' ', missesWidth-cache.misses.len() )# "
			             & " #cache.performance# #RepeatString( ' ', performanceWidth-cache.performance.len() )# "
			             & " #cache.gcs# #RepeatString( ' ', gcsWidth-cache.gcs.len() )# "
			             & " #cache.lastReap# #RepeatString( ' ', lastReapWidth-cache.lastReap.len() )#" & Chr( 10 );

			statsOutput &= RepeatString( "-", tableWidth ) & Chr(10);
		}

		return statsOutput;
	}

}