component output=false {
	property name="page_template" type="string" dbtype="varchar" maxLength="50" required=false control="templatePicker";
	property name="body"          type="string" dbtype="text"    maxLength="0"  required=false;
}