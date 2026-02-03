<cfcomponent output="false" versioned="false">
	<cfproperty name="object_b"  relationship="many-to-one"      relatedTo="object_b" />
	<cfproperty name="object_ds" relationship="select-data-view" relatedTo="viewObjectD" relationshipKey="object_c" />
</cfcomponent>