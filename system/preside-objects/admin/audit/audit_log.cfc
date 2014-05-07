component output="false" extends="preside.system.base.SystemPresideObject" versioned=false {
	property name="label"                                        maxLength="200"                                        control="none";
	property name="datecreated"                                                                   indexes="logged"      control="none";
	property name="source"           type="string"  dbtype="varchar" maxLength="100" required="true"                        control="none";
	property name="action"           type="string"  dbtype="varchar" maxLength="100" required="true"                        control="none";
	property name="type"             type="string"  dbtype="varchar" maxLength="100" required="true"                        control="none";
	property name="instance"         type="string"  dbtype="varchar" maxLength="200" required="true"                        control="none";
	property name="uri"              type="string"  dbtype="varchar" maxLength="255" required="true"                        control="none";
	property name="user_ip"          type="string"  dbtype="varchar" maxLength="15"  required="true"                        control="none";
	property name="user_agent"       type="string"  dbtype="varchar" maxLength="255" required="true"                        control="none";
	property name="user" relationship="many-to-one" relatedTo="security_user" required="true"                               control="none";
}