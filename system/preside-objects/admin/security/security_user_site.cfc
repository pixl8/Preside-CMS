/**
 * @datamanagerEnabled true
 * @versioned          false
 * @nolabel            true
 * @feature            admin
 */
component extends="preside.system.base.SystemPresideObject" displayname="Website user login token" {
	property name="user"   relationship="many-to-one" relatedTo="security_user"              uniqueindexes="userHomepage|1";
	property name="site"         type="string" dbtype="varchar" maxLength="35" required=true uniqueindexes="userHomepage|2";
	property name="homepage_url" type="string" dbtype="text"                   required=true;
}