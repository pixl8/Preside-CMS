/**
 *
 * Indicates that the given user has access to the current API
 *
 * @feature    apiManager
 * @versioned  false
 * @nolabel
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="rest_user" relationship="many-to-one" relatedto="rest_user" required=true uniqueIndexes="userapi|1" ondelete="cascade";
	property name="api" type="string" dbtype="varchar" maxlength=200           required=true uniqueIndexes="userapi|2";
}