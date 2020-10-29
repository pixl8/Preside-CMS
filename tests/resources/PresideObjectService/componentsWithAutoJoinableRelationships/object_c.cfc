<cfcomponent output="false">
	<cfproperty name="object_b" relationship="many-to-one" required="true" onupdate="cascade-if-no-cycle-check"  />
</cfcomponent>