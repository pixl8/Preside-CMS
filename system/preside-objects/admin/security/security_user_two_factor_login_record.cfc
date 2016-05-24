/**
 * Represents a historic record of a user logging in using two factor
 * authentication on a given IP and user agent combination. Used to
 * determine whether or not two factor authentication is required again
 * for a given session.
 *
 * @nolabel
 * @versioned false
 */
component extends="preside.system.base.SystemPresideObject" displayName="User 2FA Login record" {
	property name="security_user" relationship="many-to-one" relatedTo="security_user" required=true uniqueindexes="user_machine|1";

	property name="ip_address"     type="string"   dbtype="varchar" maxLength="50"  required=true uniqueindexes="user_machine|2";
	property name="user_agent"     type="string"   dbtype="varchar" maxLength="255" required=true uniqueindexes="user_machine|3";
	property name="logged_in_date" type="datetime" dbtype="datetime"                required=false;
}