/**
 * @datamanagerEnabled             true
 * @datamanagerGridFields          label,status,category,datecreated
 * @datamanagerColumnPickerFields  *,!sensitive_col,!other_sensitive_col
 * @datamanagerDefaultSortOrder    label
 * @versioned                      false
 *
 */
component {
	property name="status"              type="string" dbtype="varchar" maxlength=20  required=false default="active" indexes="status";
	property name="category"            type="string" dbtype="varchar" maxlength=50  required=false indexes="category";
	property name="notes"               type="string" dbtype="varchar" maxlength=200 required=false;
	property name="sensitive_col"       type="string" dbtype="varchar" maxlength=200 required=false;
	property name="other_sensitive_col" type="string" dbtype="varchar" maxlength=200 required=false;
}
