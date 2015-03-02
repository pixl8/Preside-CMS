<cfcomponent output="false" versioned="false">
	<cfproperty name="related_to_a"       relationship="many-to-one" relatedto="object_a" required="true"  />
	<cfproperty name="related_to_a_again" relationship="many-to-one" relatedto="object_a" required="false" />
	<cfproperty name="object_cs" relationship="one-to-many" relatedto="object_c" relationshipKey="object_b" required="false" />
</cfcomponent>