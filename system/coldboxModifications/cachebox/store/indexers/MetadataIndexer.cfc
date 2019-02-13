component extends="coldbox.system.cache.store.indexers.MetadataIndexer" {

	public any function init( required any fields ) {
		variables.instance = {
			  poolMetadata    = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init()
			, indexID         = CreateObject( "java", "java.lang.System" ).identityHashCode( this )
			, javaCollections = CreateObject( "java", "java.util.Collections" )
		};

		setFields( arguments.fields );

		return this;
	}

	public any function clear( required any objectKey ) {
		return instance.poolMetadata.remove( arguments.objectKey );
	}

	public any function getKeys() {
		return instance.javaCollections.list( instance.poolMetadata.keys() );
	}

	public any function getObjectMetadata( required any objectKey ) {
		return instance.poolMetadata.get( arguments.objectKey );
	}

	public any function setObjectMetadata( required any objectKey, required any metadata ) {
		return instance.poolMetadata.put( arguments.objectKey, arguments.metadata );
	}

	public any function objectExists( required any objectKey ) {
		return instance.poolMetadata.containsKey( arguments.objectKey );
	}

	public any function getObjectMetadataProperty( required any objectKey, required any property ) {
		var meta = getObjectMetadata( arguments.objectKey );

		return meta[ arguments.property ] ?: "";
	}

	public any function setObjectMetadataProperty( required any objectKey, required any property, required any value ) {
		var meta = getObjectMetadata( arguments.objectKey );

		if ( !IsNull( local.meta ) ) {
			meta[ arguments.property ] = arguments.value;
		}
	}

	public any function getSize() {
		return instance.poolMetadata.size();
	}
}