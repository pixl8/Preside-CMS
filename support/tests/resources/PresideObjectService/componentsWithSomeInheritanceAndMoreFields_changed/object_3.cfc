<cfcomponent output="false" tablename="test_3" tableprefix="" extends="object_2" versioned="false">

	<cfproperty name="id" dbtype="int" maxlength="0" generator="increment" />
	<cfproperty name="some_date" required="false" />
	<cfproperty name="a_new_column" />

</cfcomponent>