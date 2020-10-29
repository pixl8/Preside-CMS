component output=false versioned=false {
	property name="id" dbtype="int" generator="increment" type="numeric" maxLength="0";
	property name="lots_of_bees" dbtype="none" relationship="many-to-many" relatedTo="obj_b" relatedVia="this_is_a_very_long_name_for_the_many_to_many_linking_table_too_long_in_fact";
}