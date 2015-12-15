interface {
	public any function validate( required struct configuration, required any validationResult ) {}

	public boolean function objectExists( required string path, boolean trashed=false ) {}

	public query function listObjects( required string path ) {}

	public binary function getObject( required string path, boolean trashed=false ) {}

	public struct function getObjectInfo( required string path, boolean trashed=false ) {}

	public void function putObject( required any object, required string path ) {}

	public void function deleteObject( required string path, boolean trashed=false ) {}

	public string function softDeleteObject( required string path ) {}

	public boolean function restoreObject( required string trashedPath, required string newPath ) {}

	public string function getObjectUrl( required string path ) {}
}