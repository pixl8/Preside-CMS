<cfcomponent output="false" versioned="false">
	<cfproperty name="object_c" relationship="many-to-one" required="true" onupdate="cascade-if-no-cycle-check"  />
</cfcomponent>