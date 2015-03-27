interface {
	public boolean function objectExists( required string path ) {}

	public query function listObjects( required string path ) {}

	public binary function getObject( required string path ) {}

	public struct function getObjectInfo( required string path ) {}

	public void function putObject( required any object, required string path ) {}

	public void function deleteObject( required string path ) {}

	public string function softDeleteObject( required string path ) {}

	public boolean function restoreObject( required string trashedPath, required string newPath ) {}

	public string function getObjectUrl( required string path ) {}
}