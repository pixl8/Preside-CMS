component extends="preside.system.base.SystemPresideObject" output="false" versioned=false {
	property name="label" uniqueindexes="permission_name|2";

	property name="security_role"  relationship="many-to-one" relatedTo="security_role" uniqueindexes="permission_name|1" required=true;
}