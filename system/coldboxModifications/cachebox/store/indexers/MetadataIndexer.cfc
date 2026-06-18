/**
 * ColdBox 7.0 removed coldbox.system.cache.store.indexers.MetadataIndexer.
 * This is a standalone replacement used by Preside's ConcurrentStore.
 */
component {

	public any function init( required any fields ) {
		variables.poolMetadata    = CreateObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init()
		variables.indexID         = CreateObject( "java", "java.lang.System" ).identityHashCode( this )
		variables.javaCollections = CreateObject( "java", "java.util.Collections" )

		setFields( arguments.fields );

		return this;
	}

	public any function clear( required any objectKey ) {
		return variables.poolMetadata.remove( arguments.objectKey );
	}

	public any function getKeys() {
		return javaCollections.list( variables.poolMetadata.keys() );
	}

	public any function getObjectMetadata( required any objectKey ) {
		return variables.poolMetadata.get( arguments.objectKey );
	}

	public any function setObjectMetadata( required any objectKey, required any metadata ) {
		return variables.poolMetadata.put( arguments.objectKey, arguments.metadata );
	}

	public any function objectExists( required any objectKey ) {
		return variables.poolMetadata.containsKey( arguments.objectKey );
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

	public array function getSortedKeys(
		required any property,
		any sortType  = "text",
		any sortOrder = "asc"
	) {
		return structSort(
			variables.poolMetadata,
			arguments.sortType,
			arguments.sortOrder,
			arguments.property
		);
	}

	public void function clearAll() {
		variables.poolMetadata.clear();
	}

	public any function getSize() {
		return variables.poolMetadata.size();
	}

	public void function setFields( required any fields ) {
		variables.fields = arguments.fields;
	}

	public any function getFields() {
		return variables.fields;
	}
}
