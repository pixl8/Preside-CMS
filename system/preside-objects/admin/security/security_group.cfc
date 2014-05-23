component extends="preside.system.base.SystemPresideObject" output="false" {
	property name="label" uniqueindexes="role_name";
	property name="description"  type="string"  dbtype="varchar" maxLength="200"  required="false";
	property name="roles"        type="string"  dbtype="varchar" maxLength="1000" required="false" control="rolepicker" multiple="true";
}