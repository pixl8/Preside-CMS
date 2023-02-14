/**
 * Interface for a storage provider that can also use plain file
 * paths for operations rather than rely on binary file representations
 *
 * @autodoc
 *
 */
interface displayname="Storage provider with File system support" {


	/**
	 * Returns a full local file path for the given storage path
	 *
	 * @autodoc
	 * @path.hint    The path of the stored object
	 * @trashed.hint Whether or not the object has been "trashed"
	 * @private.hint Whether or not the object is private
	 *
	 */
	public string function getObjectLocalPath( required string path, boolean trashed=false, boolean private=false ) {}

	/**
	 * Puts an object into the store.
	 *
	 * @autodoc        true
	 * @localPath.hint Full file path of local file
	 * @path.hint      Path in the storage provider at which the object should be stored
	 * @private.hint   Whether or not the object should be stored privately
	 *
	 */
	public void function putObjectFromLocalPath( required string localPath, required string path, boolean private=false ) {}


}