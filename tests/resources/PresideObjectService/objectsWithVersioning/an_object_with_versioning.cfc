component versioned=true output=false {
	property name="label" uniqueindexes="testuniqueindex" indexes="testindex";
	property name="a_category_object" relationship="many-to-many" dbtype="none" relatedVia="category_join_object";
	property name="a_many_to_one_relationship" relationship="many-to-one" relatedTo="a_category_object" onupdate="cascade-if-no-cycle-check" ondelete="cascade-if-no-cycle-check";
}