/**
 * @datamanagerEnabled                 true
 * @versioned                          false
 * @dataManagerExportEnabled           false
 * @datamanagerDisallowedOperations    read,add,clone
 * @datamanagerGridFields              label,file_name,datecreated
 * @feature                            dataExport
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="file_name"   required="true"                                                                                                 batchEditable=false;
	property name="object_name" required="true"               control="none"                                                                    batchEditable=false;
	property name="fields"      required="true"               control="none" maxlength=5000                                    autofilter=false batchEditable=false;
	property name="exporter"    required="true" default="CSV" control="none"                                                   autofilter=false;
	property name="filter"                                    control="none" type="string" dbtype="text" feature="rulesEngine" autofilter=false batchEditable=false;
	property name="saved_filter"                              control="none" type="string" dbtype="text" feature="rulesEngine" autofilter=false batchEditable=false;
	property name="order_by"                                  control="none"                                                   autofilter=false batchEditable=false;
	property name="search_query"                              control="none"                                                   autofilter=false batchEditable=false;
}