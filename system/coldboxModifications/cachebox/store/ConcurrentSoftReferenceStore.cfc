component extends="coldbox.system.cache.store.ConcurrentSoftReferenceStore" implements="" {

	public any function init( required any cacheProvider ) {
		var fields = "hits,timeout,lastAccessTimeout,created,LastAccessed,isExpired,isSoftReference";

		instance = {
			  cacheProvider   = arguments.cacheProvider
			, storeID         = CreateObject( "java", "java.lang.System" ).identityHashCode( this )
			, pool            = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init()
			, javaCollections = CreateObject( "java", "java.util.Collections" )
			, softRefKeyMap	  = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init()
			, referenceQueue  = CreateObject( "java", "java.lang.ref.ReferenceQueue" ).init()
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
		var existsInIndex = instance.indexer.objectExists( arguments.objectKey ) && !isExpired( arguments.objectKey );

		if ( !existsInIndex ) {
			return false;
		}

		var fromCache = getQuiet( arguments.objectKey );

		if ( IsNull( local.fromCache ) ) {
			instance.indexer.clear( arguments.objectKey );
			return false;
		}

		return true;
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
		var fromCache = instance.pool.get( arguments.objectKey );

		if ( !IsNull( local.fromCache ) ) {
			if( IsInstanceOf( fromCache, "java.lang.ref.SoftReference" ) ) {
				return fromCache.get();
			}

			return fromCache;
		}
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
		var isSR   = ( arguments.timeout > 0 );
		var target = 0;

		if ( isSR ) {
			target = CreateSoftReference( arguments.objectKey, arguments.object );
		} else {
			target = arguments.object;
		}

		instance.pool.put( arguments.objectKey, target );
		instance.indexer.setObjectMetadata( arguments.objectKey, {
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
		var isSR = instance.indexer.getObjectMetadataProperty( arguments.objectKey, "isSoftReference" );

		if ( IsBoolean( local.isSR ?: "" ) && local.isSR ) {
			var fromCache = getQuiet( arguments.objectKey );
			if ( !IsNull( local.fromCache ) ) {
				instance.softRefKeyMap.remove( fromCache );
			}
		}

		var removedObj = instance.pool.remove( arguments.objectKey );
		var removedMeta = instance.indexer.clear( arguments.objectKey );

		return !IsNull( local.removedObj ) && !IsNull( local.removedMeta );
	}

	public any function softRefLookup( required any softRef ) {
		return instance.softRefKeyMap.contains( arguments.softRef );
	}

	public any function getSoftRefKey( required any softRef ) {
		return instance.softRefKeyMap.get( arguments.softRef );
	}

	private any function createSoftReference( required any objectKey, required any target ) {
		var softRef = CreateObject( "java", "java.lang.ref.SoftReference" ).init( arguments.target, getReferenceQueue() );

		instance.softRefKeyMap.put( softRef, arguments.objectKey );

		return softRef;
	}
}