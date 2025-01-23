<cfcomponent output="false" versioned="false">
	<cfproperty name="object_a"  relationship="many-to-one" relatedto="object_a" />
	<cfproperty name="object_cs" relationship="one-to-many" relatedto="object_c" relationshipKey="object_b" />
</cfcomponent>