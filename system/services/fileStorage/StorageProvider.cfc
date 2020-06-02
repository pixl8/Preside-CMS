/**
 * Interface for a storage provider that can be used to
 * abstract logic for storing and retrieving user uploaded files.
 *
 * @autodoc
 *
 */
interface displayname="Storage provider" {

	/**
	 * A method to validate proposed configuration for the provider. The validate
	 * method should ensure that the configuration works (e.g. able to connect
	 * to CDN with provided credentials) and flag any errors using the passed
	 * [[api-validationresult]] object.
	 *
	 * @autodoc
	 * @configuration.hint    a structure containing configuration keys and values
	 * @validationResult.hint A [[api-validationresult]] object with which problems can be reported.
	 *
	 */
	public any function validate( required struct configuration, required any validationResult ) {}

	/**
	 * Returns whether or not an object exists for the passed path.
	 *
	 * @autodoc
	 * @path.hint    Expected path of the object
	 * @trashed.hint Whether or not the object has been "trashed"
	 * @private.hint Whether or not the object is private
	 *
	 */
	public boolean function objectExists( required string path, boolean trashed=false, boolean private=false ) {}

	/**
	 * Returns a query of objects that live beneath the given path. Query columns should be:
	 * name, path, size and lastmodified.
	 *
	 * @autodoc
	 * @path.hint    A path prefix that the method should use when deciding which objects to return. Any object whose path begins with the provide path should be returned.
	 * @private.hint Whether or not the objects exist in the private store
	 *
	 */
	public query function listObjects( required string path, boolean private=false ) {}

	/**
	 * Returns the binary data of the object that lives at the given path.
	 *
	 * @autodoc
	 * @path.hint    The path of the stored object
	 * @trashed.hint Whether or not the object has been "trashed"
	 * @private.hint Whether or not the object is private
	 *
	 */
	public binary function getObject( required string path, boolean trashed=false, boolean private=false ) {}

	/**
	 * Returns size and lastmodified information about the object that resides at the provided path.
	 *
	 * @autodoc
	 * @path.hint    The path of the stored object
	 * @trashed.hint Whether or not the object has been "trashed"
	 * @private.hint Whether or not the object is private
	 *
	 */
	public struct function getObjectInfo( required string path, boolean trashed=false, boolean private=false ) {}

	/**
	 * Puts an object into the store.
	 *
	 * @autodoc
	 * @object.hint  Either a full path to a local file on the server, or the binary content of a file
	 * @path.hint    Path in the storage provider at which the object should be stored
	 * @private.hint Whether or not the object should be stored privately
	 *
	 */
	public void function putObject( required any object, required string path, boolean private=false ) {}


	/**
	 * Permanently deletes the object that resides at the given path.
	 *
	 * @autodoc
	 * @path.hint    The path of the stored object
	 * @trashed.hint Whether or not the object has been "trashed"
	 * @private.hint Whether or not the object is private
	 *
	 */
	public void function deleteObject( required string path, boolean trashed=false, boolean private=false ) {}

	/**
	 * "Soft" deletes the object that resides at the given path. This requires
	 * that the impelementing component moves the object to the configured "trash"
	 * storage such that it can be restored later. Must return the trashed path of the object.
	 *
	 * @autodoc
	 * @path.hint    The path of the stored object
	 * @private.hint Whether or not the object is private
	 *
	 */
	public string function softDeleteObject( required string path, boolean private=false ) {}

	/**
	 * Restores an object that has been previously "trashed"/"Soft deleted".
	 *
	 * @autodoc
	 * @trashedPath.hint Path of the stored object within the trash
	 * @newPath.hint     Path to restore the object to
	 * @private.hint 	 Whether or not the object should be restored to the private store
	 *
	 */
	public boolean function restoreObject( required string trashedPath, required string newPath, boolean private=false ) {}

	/**
	 * Should return a direct URL at which the object can be retrieved.
	 * Return an empty string to indicate that no direct URL exists.
	 *
	 * @autodoc
	 * @path.hint The path of the stored object
	 *
	 */
	public string function getObjectUrl( required string path ) {}

	/**
	 * Should move source object to target destination
	 *
	 * @autodoc
	 * @originalPath.hint      The path of the stored object
	 * @newPath.hint           The new path at which to store the object
	 * @originalIsPrivate.hint Whether or not the original stored object is stored privately
	 * @newIsPrivate.hint      Whether or not the new stored object is to be stored privately
	 *
	 */
	public void function moveObject( required string originalPath, required string newPath, boolean originalIsPrivate=false, boolean newIsPrivate=false ) {}
}