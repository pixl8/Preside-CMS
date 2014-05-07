component extends="preside.system.base.SystemPresideObject" output="false" {
	property name="label"                                                                        uniqueindexes="role_name";
	property name="key"          type="string"  dbtype="varchar" maxLength="50"  required="true" uniqueindexes="role_key";
	property name="description"  type="string"  dbtype="varchar" maxLength="200" required="false";
}