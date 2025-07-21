/**
 * @feature                        cfflow
 * @nolabel                        true
 * @versioned                      false
 * @tablePrefix                    ""
 * @datamanagerEnabled             true
 * @datamanagerAllowedOperations   read
 * @datamanagerDefaultSortOrder    datecreated
 */
component {
	property name="triggered_by_admin_user"   relationship="many-to-one" relatedto="security_user";
	property name="triggered_by_website_user" relationship="many-to-one" relatedto="website_user" feature="websiteusers";

	property name="instance" relationship="many-to-one" relatedto="cfflow_workflow_instance" required=true ondelete="cascade";

	property name="step"   required=false type="string" dbtype="varchar" maxlength=100 indexes="step" renderer="webflowInstanceStepTitle";
	property name="action" required=true type="string" dbtype="varchar" maxlength=100 indexes="action";
	property name="result" required=true type="string" dbtype="varchar" maxlength=100 indexes="result" renderer="webflowInstanceStepTitle";

	property name="state" type="string" dbtype="longtext";
}