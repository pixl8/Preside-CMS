<cfcomponent output="false">
	<cfproperty name="id"           type="numeric" label="Test ID"                                 maxLength="9"  dbtype="integer" generator="AUTOINCREMENT"                  />
	<cfproperty name="label"                       label="Test Label"                                                                                                         />
	<cfproperty name="datecreated"                 label="Test Created"       control="datepicker"                                                           required="false" />
	<cfproperty name="datemodified"                label="Test Last modified" control="datepicker"                                                           required="false" />
</cfcomponent>