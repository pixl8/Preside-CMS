component output=false versioned=false {
	property name="id" dbtype="int" generator="increment" type="numeric" maxLength="0";
	property name="lots_of_bees" dbtype="none" relationship="many-to-many" relatedTo="obj_b";
}