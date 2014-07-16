component output="false" extends="preside.system.base.SystemPresideObject" labelfield="setting" {
	property name="category" type="string" dbtype="varchar" maxlength="50" required="true"  uniqueindexes="categorysetting|1";
	property name="setting"  type="string" dbtype="varchar" maxlength="50" required="true"  uniqueindexes="categorysetting|2";
	property name="value"    type="string" dbtype="text"                   required="false";
}
