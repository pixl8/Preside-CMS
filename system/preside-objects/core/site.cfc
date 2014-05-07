component output=false extends="preside.system.base.SystemPresideObject" {
	property name="label"  uniqueindexes="sitename";
	property name="domain" type="string" maxlength="255" required="false" uniqueindexes="sitepath|1";
	property name="path"   type="string" maxlength="255" required="false" uniqueindexes="sitepath|2";
}