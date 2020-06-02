<cfcomponent output="false" tablename="test_1" tableprefix="test_" versioned="false">

	<cfproperty name="id" dbtype="int" maxlength="0" generator="increment" />
	<cfproperty name="test_property" label="Test property" dbtype="boolean" />

</cfcomponent>