<cfcomponent output="false">
	<cfproperty name="field1"  />
	<cfproperty name="field2"  />
	<cfproperty name="field3" dbtype="none" relationship="one-to-many"  relatedto="someobject" />
	<cfproperty name="field4" dbtype="none" relationship="many-to-many" relatedto="someotherobject" />
</cfcomponent>