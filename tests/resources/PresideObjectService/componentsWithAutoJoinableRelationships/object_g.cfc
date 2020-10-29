<cfcomponent output="false" versioned="false" nolabel="true">
	<cfproperty name="id" dbtype="int" maxlength="0" generator="increment" />
	<cfproperty name="object_e" relationship="many-to-one" required="false" onupdate="cascade-if-no-cycle-check" />
</cfcomponent>