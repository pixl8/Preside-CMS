/**
 * Definition of an admin-created record store. Records themselves live in custom_object_record.
 *
 * @versioned                     false
 * @datamanagerEnabled            true
 * @datamanagerGridFields         label,key,category,active,datemodified
 * @datamanagerSearchFields       label,key,category
 * @datamanagerDefaultSortOrder   label
 * @datamanagerDisallowedOperations clone,batchedit,batchdelete
 * @labelfield                    label
 * @feature                       customObjects
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="key"             type="string"  dbtype="varchar" maxlength=40  required=true uniqueindexes="customobjectkey" format="regex:^[a-z][a-z0-9_]*$";
	property name="label"           type="string"  dbtype="varchar" maxlength=200 required=true;
	property name="label_singular"  type="string"  dbtype="varchar" maxlength=200 required=true;
	property name="description"     type="string"  dbtype="text"                  required=false;
	property name="icon_class"      type="string"  dbtype="varchar" maxlength=100 required=false default="fa-database";
	property name="has_label_field" type="boolean" dbtype="boolean"               required=false default=true;
	property name="label_field"     type="string"  dbtype="varchar" maxlength=100 required=false default="label";
	property name="category"        type="string"  dbtype="varchar" maxlength=200 required=true;
	property name="active"          type="boolean" dbtype="boolean"               required=false default=true renderer="booleanBadge";
	property name="sort_order"      type="numeric" dbtype="int"                   required=false default=0;

	property name="read_groups"   relationship="many-to-many" relatedTo="security_group" relatedVia="custom_object_read_group";
	property name="manage_groups" relationship="many-to-many" relatedTo="security_group" relatedVia="custom_object_manage_group";
}
