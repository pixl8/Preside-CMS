<cfcomponent output="false" versioned="false">
	<cfproperty name="id" dbtype="int" maxlength="0" generator="increment" />
	<cfproperty name="object_e" relationship="many-to-one" required="true" onupdate="cascade-if-no-cycle-check" />
</cfcomponent>