component extends="preside.system.base.SystemPresideObject" output="false" versioned=false labelfield="key" {
	property name="key" type="string"  dbtype="varchar" maxlength="200"        required="true" uniqueindexes="userdraft|1";
	property name="owner" relationship="many-to-one" relatedTo="security_user" required="true" uniqueindexes="userdraft|2" control="none";
	property name="content" type="string" dbtype="longtext" required="false";
}