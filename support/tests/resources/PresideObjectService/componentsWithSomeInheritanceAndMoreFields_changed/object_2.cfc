<cfcomponent output="false" tablename="test_2" extends="object_1" versioned="false">

	<cfproperty name="id" dbtype="int" maxlength="0" generator="increment" />
	<cfproperty name="test_property" type="boolean" label="Test property" dbtype="bit" default="0" />
	<cfproperty name="some_date" type="string" label="Somedate" dbtype="varchar" maxLength="100" required="true" />

</cfcomponent>