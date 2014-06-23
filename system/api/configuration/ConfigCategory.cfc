component output=false accessors=true {
	property name="id"               type="string"  default="";
	property name="name"             type="string"  default="";
	property name="description"      type="string"  default="";
	property name="form"             type="string"  default="";
	property name="presideObject"    type="string"  default="";

	public struct function getMemento(){
		return {
			  id               = getId()
			, name             = getName()
			, description      = getDescription()
			, form             = getForm()
			, presideObject    = getPresideObject()
		};
	}
}