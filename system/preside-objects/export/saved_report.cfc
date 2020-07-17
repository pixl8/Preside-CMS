/**
 * @datamanagerEnabled                 true
 * @versioned                          false
 * @dataManagerExportEnabled           false
 * @datamanagerDisallowedOperations    read,add,clone
 * @datamanagerGridFields              label,file_name,datecreated
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="file_name"   required="true";
	property name="object_name" required="true"               control="none";
	property name="fields"      required="true"               control="none" maxlength=5000                                    autofilter=false;
	property name="exporter"    required="true" default="CSV" control="none"                                                   autofilter=false;
	property name="filter"                                    control="none" type="string" dbtype="text" feature="rulesEngine" autofilter=false;
	property name="saved_filter"                              control="none" type="string" dbtype="text" feature="rulesEngine" autofilter=false;
	property name="order_by"                                  control="none"                                                   autofilter=false;
	property name="search_query"                              control="none"                                                   autofilter=false;
}