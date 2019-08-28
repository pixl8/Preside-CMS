/**
 * Interface that asset queues should
 * adhere to
 *
 */
interface {

	public void function queueAssetGeneration(
		  required string assetId
		,          string versionId      = ""
		,          string derivativeName = ""
		,          string configHash     = ""
	);

	public boolean function isQueued(
		  required string assetId
		, required string derivativeName
		, required string versionId
		, required string configHash
	);

 }