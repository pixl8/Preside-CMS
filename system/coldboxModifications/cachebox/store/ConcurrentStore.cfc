component extends="coldbox.system.cache.store.ConcurrentStore" implements="" {

	public any function init( required any cacheProvider ) {
		var fields = "hits,timeout,lastAccessTimeout,created,LastAccessed,isExpired";

		variables.cacheProvider   = arguments.cacheProvider
		variables.storeID         = CreateObject( "java", "java.lang.System" ).identityHashCode( this )
		variables.pool            = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init()
		variables.javaCollections = CreateObject( "java", "java.util.Collections" )
		variables.indexer         = CreateObject( "component", "preside.system.coldboxModifications.cachebox.store.indexers.MetadataIndexer" ).init( fields )

		return this;
	}

	public any function getKeys() {
		return javaCollections.list( pool.keys() );
	}

	public any function getSize() {
		return pool.size();
	}

	public any function lookup( required any objectKey ) {
		return indexer.objectExists( arguments.objectKey )
		    && pool.containsKey( arguments.objectKey )
			&& !isExpired( arguments.objectKey );
	}

	public any function get( required any objectKey ) {
		var fromCache = getQuiet( arguments.objectKey );

		if ( !IsNull( local.fromCache ) ) {
			indexer.setObjectMetadataProperty( arguments.objectKey, "hits", Val( indexer.getObjectMetadataProperty( arguments.objectKey, "hits" ) )+1 );
			indexer.setObjectMetadataProperty( arguments.objectKey, "LastAccessed", Now() );

			return fromCache;
		}
	}

	public any function getQuiet( required any objectKey ) {
		return pool.get( arguments.objectKey );
	}

	public void function expireObject( required any objectKey ) {
		indexer.setObjectMetadataProperty( arguments.objectKey, "isExpired", true );
	}

	public any function isExpired( required any objectKey ) {
		var isExpired = indexer.getObjectMetadataProperty( arguments.objectKey, "isExpired" );

		return IsBoolean( local.isExpired ?: "" ) && isExpired;
	}

	public void function set(
		  required any objectKey
		, required any object
		,          any timeout
		,          any lastAccessTimeout
		,          any extras
	) {
		pool.put( arguments.objectKey, arguments.object );
		indexer.setObjectMetadata( arguments.objectKey, {
			  hits              = 1
			, timeout           = arguments.timeout
			, lastAccessTimeout = arguments.lastAccessTimeout
			, created           = Now()
			, LastAccessed      = Now()
			, isExpired         = false
		} );
	}

	public any function clear( required any objectKey ) {
		var removedObj = pool.remove( arguments.objectKey );
		var removedMeta = indexer.clear( arguments.objectKey );

		return !IsNull( local.removedObj ) && !IsNull( local.removedMeta );
	}
}