<cfcomponent output="false">
	<cfproperty name="test_property" />
	<cfproperty name="related_prop"                                                                control="objectpicker"                  maxLength="35" relatedto="someobject" relationship="many-to-one" />
	<cfproperty name="another_property"      label="My property"  type="date"    dbtype="datetime" control="datepicker"   required="true" />
	<cfproperty name="some_numeric_property" label="Numeric prop" type="numeric" dbtype="tinyint"  control="spinner"      required="false" minValue="1" maxValue="10" />
</cfcomponent>