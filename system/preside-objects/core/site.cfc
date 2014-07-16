component output=false extends="preside.system.base.SystemPresideObject" labelfield="name" {
	property name="name"   type="string" maxlength="200" required="true"  uniqueindexes="sitename";
	property name="domain" type="string" maxlength="255" required="false" uniqueindexes="sitepath|1";
	property name="path"   type="string" maxlength="255" required="false" uniqueindexes="sitepath|2";
}