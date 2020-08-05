/**
 * The website user reset token object represents
 * a single password reset token
 *
 * @versioned      false
 * @nolabel        true
 * @nodatemodified true
 * @feature        websiteUsers
 */
component extends="preside.system.base.SystemPresideObject" displayname="Website user reset password token" {
	property name="user" relationship="many-to-one" relatedTo="website_user"            uniqueindexes="resettoken|1";

	property name="token"  type="string" dbtype="varchar" maxLength="35"  required=true uniqueindexes="resettoken|2";
	property name="key"    type="string" dbtype="varchar" maxLength="60"  required=true;
	property name="expiry" type="date"   dbtype="datetime"                required=true indexes="tokenexpiry";
}