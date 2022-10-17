<cfcomponent output="false" versioned="false">
	<cfproperty name="related_to_a" relationship="many-to-one" relatedto="object_a" required="true"  onupdate="cascade-if-no-cycle-check" />
	<cfproperty name="object_d"     relationship="many-to-one" required="false" onupdate="cascade-if-no-cycle-check" />
</cfcomponent>