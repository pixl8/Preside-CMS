component output=false labelfield="none" {
	property name="domain" type="string" dbtype="varchar" maxlength="255" required=true uniqueindexes="sitedomain|2";
	property name="site" relationship="many-to-one"                       required=true uniqueindexes="sitedomain|1";
}