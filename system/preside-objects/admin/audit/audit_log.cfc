component output="false" extends="preside.system.base.SystemPresideObject" labelfield="detail" versioned=false {
	property name="detail"     type="string"  dbtype="varchar" maxLength="200" required=true;
	property name="source"     type="string"  dbtype="varchar" maxLength="100" required=true;
	property name="action"     type="string"  dbtype="varchar" maxLength="100" required=true;
	property name="type"       type="string"  dbtype="varchar" maxLength="100" required=true;
	property name="instance"   type="string"  dbtype="varchar" maxLength="200" required=true;
	property name="uri"        type="string"  dbtype="varchar" maxLength="255" required=true;
	property name="user_ip"    type="string"  dbtype="varchar" maxLength="15"  required=true;
	property name="user_agent" type="string"  dbtype="varchar" maxLength="255" required=true;

	property name="user" relationship="many-to-one" relatedTo="security_user" required="true";
	property name="datecreated" indexes="logged";
}