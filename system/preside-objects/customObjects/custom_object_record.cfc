/**
 * Single table for every record of every database-defined custom object.
 *
 * @versioned          false
 * @datamanagerEnabled false
 * @noLabel            false
 * @feature            customObjects
 */
component extends="preside.system.base.SystemPresideObject" {
	property name="custom_object" relationship="many-to-one" relatedTo="custom_object" required=true indexes="customobject" ondelete="cascade";
	property name="label"         type="string" dbtype="varchar" maxlength=250 required=false;
}
