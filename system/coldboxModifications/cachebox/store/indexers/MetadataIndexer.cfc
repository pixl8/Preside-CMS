component extends="coldbox.system.cache.store.indexers.MetadataIndexer" {

	public any function init( required any fields ) {
		variables.poolMetadata    = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init()
		variables.indexID         = CreateObject( "java", "java.lang.System" ).identityHashCode( this )
		variables.javaCollections = CreateObject( "java", "java.util.Collections" )

		setFields( arguments.fields );

		return this;
	}

	public any function clear( required any objectKey ) {
		return poolMetadata.remove( arguments.objectKey );
	}

	public any function getKeys() {
		return javaCollections.list( poolMetadata.keys() );
	}

	public any function getObjectMetadata( required any objectKey ) {
		return poolMetadata.get( arguments.objectKey );
	}

	public any function setObjectMetadata( required any objectKey, required any metadata ) {
		return poolMetadata.put( arguments.objectKey, arguments.metadata );
	}

	public any function objectExists( required any objectKey ) {
		return poolMetadata.containsKey( arguments.objectKey );
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
		return poolMetadata.size();
	}
}