component siteFiltered=true output=false {

<!--- properties --->
	property name="label" uniqueindexes="label" indexes="someindex";
	property name="slug" dbtype="varchar"  maxLength="50" required="false" uniqueindexes="slug|2";
	property name="parent" relationship="many-to-one" relatedTo="object_with_site_tenancy" required="false" uniqueindexes="slug|1";
}