component extends="coldbox.system.cache.store.ConcurrentStore" implements="" {

	public any function init( required any cacheProvider ) {
		var fields = "hits,timeout,lastAccessTimeout,created,LastAccessed,isExpired";

		instance = {
			  cacheProvider   = arguments.cacheProvider
			, storeID         = CreateObject( "java", "java.lang.System" ).identityHashCode( this )
			, pool            = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init()
			, javaCollections = CreateObject( "java", "java.util.Collections" )
			, indexer         = CreateObject( "component", "preside.system.coldboxModifications.cachebox.store.indexers.MetadataIndexer" ).init( fields )
		};

		return this;
	}

	public any function getKeys() {
		return instance.javaCollections.list( instance.pool.keys() );
	}

	public any function getSize() {
		return instance.pool.size();
	}

	public any function lookup( required any objectKey ) {
		return instance.indexer.objectExists( arguments.objectKey )
		    && instance.pool.contains( arguments.objectKey )
			&& !isExpired( arguments.objectKey );
	}

	public any function get( required any objectKey ) {
		var fromCache = getQuiet( arguments.objectKey );

		if ( !IsNull( local.fromCache ) ) {
			instance.indexer.setObjectMetadataProperty( arguments.objectKey, "hits", Val( instance.indexer.getObjectMetadataProperty( arguments.objectKey, "hits" ) )+1 );
			instance.indexer.setObjectMetadataProperty( arguments.objectKey, "LastAccessed", Now() );

			return fromCache;
		}
	}

	public any function getQuiet( required any objectKey ) {
		return instance.pool.get( arguments.objectKey );
	}

	public void function expireObject( required any objectKey ) {
		instance.indexer.setObjectMetadataProperty( arguments.objectKey, "isExpired", true );
	}

	public any function isExpired( required any objectKey ) {
		var isExpired = instance.indexer.getObjectMetadataProperty( arguments.objectKey, "isExpired" );

		return IsBoolean( local.isExpired ?: "" ) && isExpired;
	}

	public void function set(
		  required any objectKey
		, required any object
		,          any timeout
		,          any lastAccessTimeout
		,          any extras
	) {
		instance.pool.put( arguments.objectKey, arguments.object );
		instance.indexer.setObjectMetadata( arguments.objectKey, {
			  hits              = 1
			, timeout           = arguments.timeout
			, lastAccessTimeout = arguments.lastAccessTimeout
			, created           = Now()
			, LastAccessed      = Now()
			, isExpired         = false
		} );
	}

	public any function clear( required any objectKey ) {
		var removedObj = instance.pool.remove( arguments.objectKey );
		var removedMeta = instance.indexer.clear( arguments.objectKey );

		return !IsNull( local.removedObj ) && !IsNull( local.removedMeta );
	}
}