/**
 * The website user login token object represents a "remember me" authentication token. This system is being implemented as advocated here: [http://jaspan.com/improved_persistent_login_cookie_best_practice](http://jaspan.com/improved_persistent_login_cookie_best_practice)
 *
 * @nolabel
 */
component extends="preside.system.base.SystemPresideObject" displayname="Website user login token" {
	property name="user"   relationship="many-to-one" relatedTo="security_user"         uniqueindexes="userSeries|1";
	property name="series" type="string" dbtype="varchar" maxLength="35" required=true  uniqueindexes="userSeries|2";
	property name="token"  type="string" dbtype="varchar" maxLength="60" required=true;
}