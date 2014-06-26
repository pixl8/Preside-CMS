component output=false accessors=true {
	property name="id"               type="string"  default="";
	property name="name"             type="string"  default="";
	property name="description"      type="string"  default="";
	property name="viewlet"          type="string"  default="";
	property name="defaultForm"      type="string"  default="";
	property name="addForm"          type="string"  default="";
	property name="editForm"         type="string"  default="";
	property name="presideObject"    type="string"  default="";
	property name="hasHandler"       type="boolean" default=false;
	property name="layouts"          type="string"  default="";

	public boolean function hasHandler() output=false {
		return getHasHandler();
	}
	public array function listLayouts() output=false {
		return ListToArray( getLayouts() );
	}

	public struct function getMemento(){
		return {
			  id               = getId()
			, name             = getName()
			, viewlet          = getViewlet()
			, description      = getDescription()
			, defaultForm      = getDefaultForm()
			, addForm          = getAddForm()
			, editForm         = getEditForm()
			, presideObject    = getPresideObject()
			, hasHandler       = hasHandler()
			, layouts          = listLayouts()
		};
	}
}