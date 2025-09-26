component output="false" versioned="false" {
	property name="id"       dbtype="varchar" maxlength="35" generator="UUID";
	property name="label"    dbtype="varchar" maxlength="250" required="true";
	property name="status"   dbtype="varchar" maxlength="20" required="true" enum="ctestStatusEnum";
	property name="priority" dbtype="int" required="true";
}
