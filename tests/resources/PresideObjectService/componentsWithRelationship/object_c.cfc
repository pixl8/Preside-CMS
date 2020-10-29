<cfcomponent output="false" versioned="false">
	<cfproperty name="object_b" relationship="many-to-one" required="true" ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check"  />
</cfcomponent>