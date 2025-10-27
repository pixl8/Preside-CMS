/**
 * @versioned          false
 * @dataManagerEnabled true
 */
component {

	property name="object_name" type="string" dbtype="varchar"  searchEnabled=true searchSearchable=false batchEditable=false autoFilter=false;
	property name="record_id"   type="string" dbtype="varchar"  searchEnabled=true searchSearchable=false batchEditable=false autoFilter=false;
	property name="data"        type="string" dbtype="longtext" searchEnabled=true searchSearchable=false batchEditable=false autoFilter=false;

}