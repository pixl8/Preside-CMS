component extends="coldbox.system.cache.store.ConcurrentSoftReferenceStore" implements="" {

	public any function init( required any cacheProvider ) {
		var fields = "hits,timeout,lastAccessTimeout,created,LastAccessed,isExpired,isSoftReference";

		variables.cacheProvider   = arguments.cacheProvider
		variables.storeID         = CreateObject( "java", "java.lang.System" ).identityHashCode( this )
		variables.pool            = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init()
		variables.javaCollections = CreateObject( "java", "java.util.Collections" )
		variables.softRefKeyMap	  = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init()
		variables.referenceQueue  = CreateObject( "java", "java.lang.ref.ReferenceQueue" ).init()
		variables.indexer         = CreateObject( "component", "preside.system.coldboxModifications.cachebox.store.indexers.MetadataIndexer" ).init( fields )

		return this;
	}

	public any function getKeys() {
		return variables.javaCollections.list( variables.pool.keys() );
	}

	public any function getSize() {
		return variables.pool.size();
	}

	public any function lookup( required any objectKey ) {
		var existsInIndex = variables.indexer.objectExists( arguments.objectKey ) && !isExpired( arguments.objectKey );

		if ( !existsInIndex ) {
			return false;
		}

		var fromCache = getQuiet( arguments.objectKey );

		if ( IsNull( local.fromCache ) ) {
			variables.indexer.clear( arguments.objectKey );
			return false;
		}

		return true;
	}

	public any function get( required any objectKey ) {
		var fromCache = getQuiet( arguments.objectKey );

		if ( !IsNull( local.fromCache ) ) {
			variables.indexer.setObjectMetadataProperty( arguments.objectKey, "hits", Val( variables.indexer.getObjectMetadataProperty( arguments.objectKey, "hits" ) )+1 );
			variables.indexer.setObjectMetadataProperty( arguments.objectKey, "LastAccessed", Now() );

			return fromCache;
		}

	}

	public any function getQuiet( required any objectKey ) {
		var fromCache = variables.pool.get( arguments.objectKey );

		if ( !IsNull( local.fromCache ) ) {
			if( IsInstanceOf( fromCache, "java.lang.ref.SoftReference" ) ) {
				return fromCache.get();
			}

			return fromCache;
		}
	}

	public void function expireObject( required any objectKey ) {
		variables.indexer.setObjectMetadataProperty( arguments.objectKey, "isExpired", true );
	}

	public any function isExpired( required any objectKey ) {
		var isExpired = variables.indexer.getObjectMetadataProperty( arguments.objectKey, "isExpired" );

		return IsBoolean( local.isExpired ?: "" ) && isExpired;
	}

	public void function set(
		  required any objectKey
		, required any object
		,          any timeout
		,          any lastAccessTimeout
		,          any extras
	) {
		var isSR   = ( arguments.timeout > 0 );
		var target = 0;

		if ( isSR ) {
			target = CreateSoftReference( arguments.objectKey, arguments.object );
		} else {
			target = arguments.object;
		}

		variables.pool.put( arguments.objectKey, target );
		variables.indexer.setObjectMetadata( arguments.objectKey, {
			  hits              = 1
			, timeout           = arguments.timeout
			, lastAccessTimeout = arguments.lastAccessTimeout
			, created           = Now()
			, LastAccessed      = Now()
			, isExpired         = false
			, isSoftReference   = isSR
		} );
	}

	public any function clear( required any objectKey ) {
		var isSR = variables.indexer.getObjectMetadataProperty( arguments.objectKey, "isSoftReference" );

		if ( IsBoolean( local.isSR ?: "" ) && local.isSR ) {
			var fromCache = getQuiet( arguments.objectKey );
			if ( !IsNull( local.fromCache ) ) {
				variables.softRefKeyMap.remove( fromCache );
			}
		}

		var removedObj = variables.pool.remove( arguments.objectKey );
		var removedMeta = variables.indexer.clear( arguments.objectKey );

		return !IsNull( local.removedObj ) && !IsNull( local.removedMeta );
	}

	public any function softRefLookup( required any softRef ) {
		return variables.softRefKeyMap.containsKey( arguments.softRef );
	}

	public any function getSoftRefKey( required any softRef ) {
		return variables.softRefKeyMap.get( arguments.softRef );
	}

	private any function createSoftReference( required any objectKey, required any target ) {
		var softRef = CreateObject( "java", "java.lang.ref.SoftReference" ).init( arguments.target, getReferenceQueue() );

		variables.softRefKeyMap.put( softRef, arguments.objectKey );

		return softRef;
	}
}