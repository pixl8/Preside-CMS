<cfcomponent output="false" tablename="test_2" extends="object_1" versioned="false">

	<cfproperty name="test_property" type="boolean" label="Test property" dbtype="boolean" default="0" />
	<cfproperty name="some_date" type="date" label="Somedate" dbtype="datetime" required="true" />

</cfcomponent>