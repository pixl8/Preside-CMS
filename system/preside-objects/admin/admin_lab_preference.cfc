/**
 * Per-user override for a Labs experiment: default (follow system), on, or off.
 *
 * @nolabel             true
 * @versioned           false
 * @datamanagerEnabled  false
 * @feature             admin
 */
component extends="preside.system.base.SystemPresideObject" displayName="Admin lab preference" {
	property name="security_user" relationship="many-to-one" relatedTo="security_user" required=true uniqueindexes="userexperiment|1" ondelete="cascade";
	property name="experiment"    type="string" dbtype="varchar" maxlength=50 required=true uniqueindexes="userexperiment|2";
	property name="value"         type="string" dbtype="varchar" maxlength=10 required=true enum="labPreference" default="default";
}
