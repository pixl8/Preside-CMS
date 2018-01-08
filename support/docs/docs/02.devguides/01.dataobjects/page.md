---
id: dataobjects
title: Data objects
---

## Overview

**Preside Data Objects** are the data layer implementation for PresideCMS. Just about everything in the system that persists data to the database uses Preside Data Objects to do so.

The Preside Data Objects system is deeply integrated into the CMS:

* Input forms and other administrative GUIs can be automatically generated for your preside objects
* [[dataobjectviews]] provide a way to present your data to end users without the need for handler or service layers
*  The Data Manager provides a GUI for managing your client specific data and is based on entirely on Preside Data Objects
* Your preside objects can have their data tied to individual [[workingwithmultiplesites]], without the need for any extra programming of site filters.

The following guide is intended as a thorough overview of Preside Data Objects. For API reference documentation, see [[api-presideobjectservice]].

## Object CFC Files

Data objects are represented by ColdFusion Components (CFCs). A typical object will look something like this:

```luceescript
component {
    property name="name"          type="string" dbtype="varchar" maxlength="200" required=true;
    property name="email_address" type="string" dbtype="varchar" maxlength="255" required=true uniqueindexes="email";

    property name="tags" relationship="many-to-many" relatedto="tag";
}
```

A singe CFC file represents a table in your database. Properties defined using the `property` tag represent fields and/or relationships on the table.

### Database table names

By default, the name of the database table will be the name of the CFC file prefixed with **pobj_**. For example, if the file was `person.cfc`, the table name would be **pobj_person**.

You can override these defaults with the `tablename` and `tableprefix` attributes:

```luceescript
/**
 * @tablename   mytable
 * @tableprefix mysite_
 */
component {
    // .. etc.
}
```

>>> All of the preside objects that are provided by the core PresideCMS system have their table names prefixed with **psys_**.

### Registering objects

The system will automatically register any CFC files that live under the `/application/preside-objects` folder of your site (and any of its sub-folders). Each .cfc file will be registered with an ID that is the name of the file without the ".cfc" extension.

For example, given the directory structure below, *four* objects will be registered with the IDs *blog*, *blogAuthor*, *event*, *eventCategory*:

```
/application
    /preside-objects
        /blogs
            blog.cfc
            blogAuthor.cfc
        /events
            event.cfc
            eventCategory.cfc
```

>>> Notice how folder names are ignored. While it is useful to use folders to organise your Preside Objects, they carry no logical meaning in the system.

#### Extensions and core objects

For extensions, the system will search for CFC files in a `/preside-objects` folder at the root of your extension.

Core system Preside Objects can be found at `/preside/system/preside-objects`.

## Properties

Properties represent fields on your database table or mark relationships between objects (or both).

Attributes of the properties describe details such as data type, data length and validation requirements. At a minimum, your properties should define a *name*, *type* and *dbtype* attribute. For *varchar* fields, a *maxLength* attribute is also required. You will also typically need to add a *required* attribute for any properties that are a required field for the object:

```luceescript
component {
    property name="name"          type="string"  dbtype="varchar" maxLength="200" required=true;
    property name="max_delegates" type="numeric" dbtype="int"; // not required
}
```

### Standard attributes

While you can add any arbitrary attributes to properties (and use them for your own business logic needs), the system will interpret and use the following standard attributes:

<div class="table-resp">
    <table class="table">
        <thead>
            <tr>
                <th>Name</th>
                <th>Required</th>
                <th>Default</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>
            <tr><td>name</td>                 <td>Yes</td> <td>*N/A*</td>     <td>Name of the field</td>                                                                                                                                                                                                                                               </tr>
            <tr><td>type</td>                 <td>No</td>  <td>"string"</td>  <td>CFML type of the field. Valid values: *string*, *numeric*, *boolean*, *date*</td>                                                                                                                                                                                    </tr>
            <tr><td>dbtype</td>               <td>No</td>  <td>"varchar"</td> <td>Database type of the field to be define on the database table field        </td>                                                                                                                                                                                     </tr>
            <tr><td>maxLength</td>            <td>No</td>  <td>0</td>         <td>For dbtypes that require a length specification. If zero, the max size will be used.</td>                                                                                                                                                                            </tr>
            <tr><td>required</td>             <td>No</td>  <td>**false**</td> <td>Whether or not the field is required.    </td>                                                                                                                                                                                                                       </tr>
            <tr><td>default</td>              <td>No</td>  <td>""</td>        <td>A default value for the property. Can be dynamically created, see :ref:`presideobjectsdefaults`</td>                                                                                                                                                                 </tr>
            <tr><td>indexes</td>              <td>No</td>  <td>""</td>        <td>List of indexes for the field, see :ref:`preside-objects-indexes`</td>                                                                                                                                                                                               </tr>
            <tr><td>uniqueindexes</td>        <td>No</td>  <td>""</td>        <td>List of unique indexes for the field, see :ref:`preside-objects-indexes`</td>                                                                                                                                                                                        </tr>
            <tr><td>control</td>              <td>No</td>  <td>"default"</td> <td>The default form control to use when rendering this field in a Preside Form. If set to 'default', the value for this attribute will be calculated based on the value of other attributes. See :doc:`/devguides/formcontrols` and :doc:`/devguides/formlayouts`.</td> </tr>
            <tr><td>renderer</td>             <td>No</td>  <td>"default"</td> <td>The default content renderer to use when rendering this field in a view. If set to 'default', the value for this attribute will be calculated based on the value of other attributes. (reference needed here).</td>                                                  </tr>
            <tr><td>minLength</td>            <td>No</td>  <td>*none*</td>    <td>Minimum length of the data that can be saved to this field. Used in form validation, etc. </td>                                                                                                                                                                      </tr>
            <tr><td>minValue</td>             <td>No</td>  <td>*none*</td>    <td>The minumum numeric value of data that can be saved to this field. *For numeric types only*.</td>                                                                                                                                                                    </tr>
            <tr><td>maxValue</td>             <td>No</td>  <td>*N/A*</td>     <td>The maximum numeric value of data that can be saved to this field. *For numeric types only*.</td>                                                                                                                                                                    </tr>
            <tr><td>format</td>               <td>No</td>  <td>*N/A*</td>     <td>Either a regular expression or named validation filter (reference needed) to validate the incoming data for this field</td>                                                                                                                                          </tr>
            <tr><td>pk</td>                   <td>No</td>  <td>**false**</td> <td>Whether or not this field is the primary key for the object, *one field per object*. By default, your object will have an *id* field that is defined as the primary key. See :ref:`preside-objects-default-properties` below.</td>                                   </tr>
            <tr><td>generator</td>            <td>No</td>  <td>"none"</td>    <td>Named generator for generating a value for this field when inserting/updating a record with the value of this field ommitted. See "Generated fields", below.</td>
            <tr><td>generate</td>             <td>No</td>  <td>"never"</td>   <td>If using a generator, indicates when to generate the value. Valid values are "never", "insert" and "always".</td>
            <tr><td>formula</td>              <td>No</td>  <td>""</td>        <td>Allows you to define a field that does not exist in the database, but can be selected and used in the application. This attribute should consist of arbitrary SQL to produce a value. See "Formula fields", below.</td>
            <tr><td>relationship</td>         <td>No</td>  <td>"none"</td>    <td>Either *none*, *many-to-one* or *many-to-many*. See :ref:`preside-objects-relationships`, below.</td>                                                                                                                                                                </tr>
            <tr><td>relatedTo</td>            <td>No</td>  <td>"none"</td>    <td>Name of the Preside Object that the property is defining a relationship with. See :ref:`preside-objects-relationships`, below.</td>                                                                                                                                  </tr>
            <tr><td>relatedVia</td>           <td>No</td>  <td>""</td>        <td>Name of the object through which a many-to-many relationship will pass. If it does not exist, the system will created it for you.  See :ref:`preside-objects-relationships`, below.</td>                                                                             </tr>
            <tr><td>relationshipIsSource</td> <td>No</td>  <td>**true**</td>  <td>In a many-to-many relationship, whether or not this object is regarded as the "source" of the relationship. If not, then it is regarded as the "target". See :ref:`preside-objects-relationships`, below.</td>                                                       </tr>
            <tr><td>relatedViaSourceFk</td>   <td>No</td>  <td>""</td>        <td>The name of the source object's foreign key field in a many-to-many relationship's pivot table. See :ref:`preside-objects-relationships`, below.</td>                                                                                                                </tr>
            <tr><td>relatedViaTargetFk</td>   <td>No</td>  <td>""</td>        <td>The name of the target object's foreign key field in a many-to-many relationship's pivot table. See :ref:`preside-objects-relationships`, below.</td>                                                                                                                </tr>
            <tr><td>enum</td>                 <td>No</td>  <td>""</td>        <td>The name of the configured enum to use with this field. See "ENUM properties", below.</tr>
        </tbody>
    </table>
</div>

### Default properties

The bare minimum code requirement for a working Preside Data Object is:

```luceescript
component {}
```

Yes, you read that right, an "empty" CFC is an effective Preside Data Object. This is because, by default, Preside Data Objects will be automatically given  `id`, `label`, `datecreated` and `datemodified` properties. The above example is equivalent to:

```luceescript
component {
    property name="id"           type="string" dbtype="varchar"   required=true maxLength="35" generator="UUID" pk=true;
    property name="label"        type="string" dbtype="varchar"   required=true maxLength="250";
    property name="datecreated"  type="date"   dbtype="datetime" required=true;
    property name="datemodified" type="date"   dbtype="datetime" required=true;
}
```

#### The ID Field

The ID field will be the primary key for your object. We have chosen to use a UUID for this field so that data migrations between databases are achievable. If, however, you wish to use an auto incrementing numeric type for this field, you could do so by overriding the `type`, `dbtype` and `generator` attributes:

```luceescript
component {
    property name="id" type="numeric" dbtype="int" generator="increment";
}
```

The same technique can be used to have a primary key that does not use any sort of generator (you would need to pass your own IDs when inserting data):

```luceescript
component {
    property name="id" generator="none";
}
```

>>>>>> Notice here that we are just changing the attributes that we want to modify (we do not specify `required` or `pk` attributes). All the default attributes will be applied unless you specify a different value for them.

#### The Label field

The **label** field is used by the system for building automatic GUI selectors that allow users to choose your object records.

![Screenshot showing a record picker for a "Blog author" object](images/screenshots/object_picker_example.png)


If you wish to use a different property to represent a record, you can use the `labelfield` attribute on your CFC, e.g.:

```luceescript
/**
 * @labelfield title
 *
 */
component {
    property name="title" type="string" dbtype="varchar" maxlength="100" required=true;
    // etc.
}
```

If you do not want your object to have a label field at all (i.e. you know it is not something that will ever be selectable, and there is no logical field that might be used as a string representation of a record), you can add a `nolabel=true` attribute to your CFC:

```luceescript
/**
 * @nolabel true
 *
 */
component {
    // ... etc.
}
```

#### The DateCreated and DateModified fields

These do exactly what they say on the tin. If you use the APIs to insert and update your records, the values of these fields will be set automatically for you.


### Default values for properties

You can use the `default` attribute on a property tag to define a default value for a property. This value will be used during an `insertData()` operation when no value is supplied for the property. E.g.

```luceescript
component {
    // ...
    property name="max_attendees" type="numeric" dbtype="int" required=false default=100;
}
```

#### Dynamic defaults

Default values can also be generated dynamically at runtime. Currently, this comes in two flavours:

1. Supplying raw CFML to be evaluated at runtime
2. Supplying the name of a method defined in your object that will be called at runtime, this method will be passed a 'data' argument that is a structure containing the data to be inserted

For raw CFML, prefix your value with `cfml:`, e.g. `cfml:CreateUUId()`. For methods that are defined on your object, use `method:methodName`. e.g.

```luceescript
component  {
    // ...
    property name="event_start_date" type="date"   dbtype="date"                      required=false default="cfml:Now()";
    property name="slug"             type="string" dbtype="varchar"   maxlength="200" required=false default="method:calculateSlug";

    public string function calculateSlug( required struct data ) {
        return LCase( ReReplace( data.label ?: "", "\W", "_", "all" ) );
    }
}
```

>>> As of Preside 10.8.0, this approach is deprecated and you should use generated fields instead (see below)

### Generated fields

As of **10.8.0**, generators allow you to dynamically generate the value of a property when a record is first being inserted and, optionally, when a record is updated. The `generate` attribute of a property dictates _when_ to use a generator. Valid values are:

* `never` (default), never generate the value
* `insert`, only generate a value when a record is first inserted
* `always`, generate a value on both insert and update of records

The `generator` attribute itself then allows you to use a system pre-defined generator or use your own by prefixing the generator with `method:` (the method name that follows should be defined on your object). For example:

```luceescript
component {
    // ...

    property name="alternative_pk"   type="string" dbtype="varchar" maxlength=35 generate="insert" generator="UUID";
    property name="description"      type="string" dbtype="text";
    property name="description_hash" type="string" dbtype="varchar" maxlength=32 generate="always" generator="method:hashDescription";

    // ...

    // The method will receive a single argument that is the struct
    // of data passed to the insertData() or updateData() methods
    public any function hashDescription( required struct changedData ) {
        if ( changedData.keyExists( "description" ) ) {
            if ( changedData.description.len() ) {
                return Hash( changedData.description );
            }

            return "";
        }
        return; // return NULL to not alter the value when no description is being updated
    }
}
```

The core system provides you with three named generators:

* `UUID` - uses `CreateUUId()` to generate a UUID for your field. This is used by default for the primary key in preside objects.
* `timestamp` - uses `Now()` to auto generate a timestamp for your field
* `hash` - used in conjunction with a `generateFrom` attribute that should be a list of other properties which to concatenate and generate an MD5 hash from

### Formula fields

Properties that define a formula are not generated as fields in your database tables. Instead, they are made available to your application to be selected in `selectData` queries. The value of the `formula` attribute should be a valid SQL statement that can be used in a SQL `select` statement and include `${prefix}` tokens before any field definitions (see below for an explanation). For example:

```luceescript
/**
 * @datamanagerGridFields title,comment_count,datemodified
 *
 */
component {
    // ...

    property name="comments" relationship="one-to-many" relatedto="article_comment";
    property name="comment_count" formula="Count( distinct ${prefix}comments.id )" type="numeric";

    // ...
}
```

```luceescript
articles = articleDao.selectData(
    selectFields = [ "id", "title", "comment_count" ]
);
```

Formula fields can also be used in your DataManager data grids and be assigned labels in your object's i18n `.properties` file.

>>> Note that formula fields are only selected when _explicitly defined_ in your `selectFields`. If you leave `selectData` to return "all" fields, only the properties that are stored in the database will be returned.

#### Formula ${prefix} token

The `${prefix}` token in formula fields allows your formula field to be used in more complex select queries that traverse your data model's relationships. Another example, this time a `person` cfc:

```luceescript
component {
    // ...
    property name="first_name" ...;
    property name="last_name"  ...;

    property name="full_name" formula="Concat( ${prefix}first_name, ' ', ${prefix}last_name )";
    // ...
}
```
Now, let us imagine we have a company object, with an "employees" `one-to-many` property that relates to our `person` object above. We may want to select employees from a company:

```luceescript
var employees = companyDao.selectData(
      id           = arguments.companyId
    , selectFields = [ "employees.id", "employees.full_name" ]
);
```

The `${prefix}` token allows us to take the `employees.` prefix of the `full_name` field and replace it so that the final select SQL becomes: `Concat( employees.first_name, ' ', employees.last_name )`. Without a `${prefix}` token, your formula field will only work when selecting directly from the object in which the property is defined, it will not work when traversing relationships as with the example above.


### ENUM properties

Properties defined with an `enum` attribute implement an application enforced ENUM system. Named ENUM types are defined in your application's `Config.cfc` and can then be attributed to a property which then automatically limits and validates the options that are available to the field. ENUM options are saved to the database as a plain string; we avoid any mapping with integer values to keep the implementation portable and simple. Example ENUM definitions in `Config.cfc`:

```luceescript
settings.enum = {};
settings.enum.redirectType                = [ "301", "302" ];
settings.enum.pageAccessRestriction       = [ "inherit", "none", "full", "partial" ];
settings.enum.pageIframeAccessRestriction = [ "inherit", "block", "sameorigin", "allow" ];
```

In addition to the `Config.cfc` definition, each ENUM type should have a corresponding `.properties` file to define the labels and optional description of each item. The file must live at `/i18n/enum/{enumTypeId}.properties`. For example:


```properties
# /i18n/enum/redirectType.properties
301.label=301 Moved Permanently
301.description=A 301 redirect indicates that the resource has been *permanently* moved to the new locations. This is particularly important to use for moved content as it instructs search engines to index the new location, potentially without losing any SEO rankings. Browsers will aggressively cache these redirects to avoid wasted calls to a URL that it has been told is moved.

302.label=302 Found (Temporary redirect)
302.description=A 302 redirect indicates that the resource has been *temporarily* moved to the new location. Use this only when you know that you will/might reinstate the original source URL at some point in time.
```

### Defining relationships with properties

Relationships are defined on **property** tags using the `relationship` and `relatedTo` attributes. For example:

```luceescript
// eventCategory.cfc
component {}

// event.cfc
component {
    property name="category" relationship="many-to-one" relatedto="eventCategory" required=true;
}
```

If you do not specify a `relatedTo` attribute, the system will assume that the foreign object has the same name as the property field. For example, the two objects below would be related through the `eventCategory` property of the `event` object:

```luceescript
// eventCategory.cfc
component {}

// event.cfc
component {
    property name="eventCategory" relationship="many-to-one" required=true;
}
```

#### One to Many relationships

In the examples, above, we define a **one to many** style relationship between `event` and `eventCategory` by adding a foreign key property to the `event` object.

The `category` property will be created as a field in the `event` object's database table. Its datatype will be automatically derived from the primary key field in the `eventCategory` object and a Foreign Key constraint will be created for you.

>>> The `event` object lives on the **many** side of this relationship (there are *many events* to *one category*), hence why we use the relationship type, *many-to-one*.

You can also declare the relationship on the other side (i.e. the 'one' side). This will allow you to traverse the relationship from either angle. e.g. we could add a 'one-to-many' property on the `eventCategory.cfc` object; this will not create a field in the database table, but will allow you to query the relationship from the category viewpoint:

```luceescript
// eventCategory.cfc
component {
    // note that the 'relationshipKey' property is the FK in the event object
    // this will default to the name of this object
    property name="events" relationship="one-to-many" relatedTo="event" relationshipKey="eventCategory";
}

// event.cfc
component {
    property name="eventCategory" relationship="many-to-one" required=true;
}
```

#### Many to Many relationships

If we wanted an event to be associated with multiple event categories, we would want to use a **Many to Many** relationship:

```luceescript
// eventCategory.cfc
component {}

// event.cfc
component {
    property name="eventCategory" relationship="many-to-many";
}
```

In this scenario, there will be no `eventCategory` field created in the database table for the `event` object. Instead, a "pivot" database table will be automatically created that looks a bit like this (in MySQL):

```sql
-- table name derived from the two related objects, delimited by __join__
create table `pobj_event__join__eventcategory` (
    -- table simply has a field for each related object
      `event`         varchar(35) not null
    , `eventcategory` varchar(35) not null

    -- plus we always add a sort_order column, should you care about
    -- the order in which records are related
    , `sort_order`    int(11)     default null

    -- unique index on the event and eventCategory fields
    , unique key `ux_event__join__eventcategory` (`event`,`eventcategory`)

    -- foreign key constraints on the event and eventCategory fields
    , constraint `fk_1` foreign key (`event`        ) references `pobj_event`         (`id`) on delete cascade on update cascade
    , constraint `fk_2` foreign key (`eventcategory`) references `pobj_eventcategory` (`id`) on delete cascade on update cascade
) ENGINE=InnoDB;
```

>>> Unlike **many to one** relationships, the **many to many** relationship can be defined on either or both objects in the relationship. That said, you will want to define it on the object(s) that make use of the relationship. In the event / eventCategory example, this will most likely be the event object. i.e. `event.insertData( label=eventName, eventCategory=listOfCategoryIds )`.

#### "Advanced" Many to Many relationships

You can excert a little more control over your many-to-many relationships by making use of some extra, non-required, attributes:

```luceescript
// event.cfc
component {
    property name                 = "eventCategory"
             relationship         = "many-to-many"
             relatedTo            = "eventCategory"
             relationshipIsSource = false              // the event object is regarded as the 'target' side of the relationship rather than the 'source' (default is 'source' when relationship defined in the object)
             relatedVia           = "event_categories" // create a new auto pivot object called "event_categories" rather than the default "event__join__eventCategory"
             relatedViaSourceFk   = "cat"              // name the foreign key field to the source object (eventCategory) to be just 'cat'
             relatedViaTargetFk   = "ev";              // name the foreign key field to the target object (event) to be just 'ev'
}
```

TODO: explain these in more detail. In short though, these attributes control the names of the pivot table and foreign keys that get automatically created for you. If you leave them out, PresideCMS will figure out sensible defaults for you.

As well as controlling the automatically created pivot table name with "relatedVia", you can also use this attribute to define a relationship that exists through a pre-existing pivot object.

>>>>>> If you have multiple many-to-many relationships between the same two objects, you will **need** to use the `relatedVia` attribute to ensure that a different pivot table is created for each context.

### Defining indexes and unique constraints

The Preside Object system allows you to define database indexes on your fields using the `indexes` and `uniqueindexes` attributes. The attributes expect a comma separated list of index definitions. An index definition can be either an index name or combination of index name and field position, separated by a pipe character. For example:

```luceescript
// event.cfc
component {
    property name="category" indexes="category,categoryName|1" required=true relationship="many-to-one" ;
    property name="name"     indexes="categoryName|2"          required=true type="string" dbtype="varchar" maxlength="100";
    // ...
}
```

The example above would result in the following index definitions:

```sql
create index ix_category     on pobj_event( category );
create index ix_categoryName on pobj_event( category, name );
```

The exact same syntax applies to unique indexes, the only difference being the generated index names are prefixed with `ux_` rather than `ix_`.

## Keeping in sync with the database

When you reload your application, the system will attempt to synchronize your object definitions with the database. While it does a reasonably good job at doing this, there are some considerations:

* If you add a new, required, field to an object that has existing data in the database, an exception will be raised. This is because you cannot add a `NOT NULL` field to a table that already has data. *You will need to provide upgrade scripts to make this type of change to an existing system.*

* When you delete properties from your objects, the system will rename the field in the database to `_deprecated_yourfield`. This prevents accidental loss of data but can lead to a whole load of extra fields in your DB during development.

* The system never deletes whole tables from your database, even when you delete the object file

## Working with the API

The `PresideObjectService` service object provides methods for performing CRUD operations on the data along with other useful methods for querying the metadata of each of your data objects. There are two ways in which to interact with the API:

1. Obtain an instance the `PresideObjectService` and call its methods directly
2. Obtain an "auto service object" for the specific object you wish to work with and call its decorated CRUD methods as well as any of its own custom methods

You may find that all you wish to do is to render a view with some data that is stored through the Preside Object service. In this case, you can bypass the service layer APIs and use the [[presidedataobjectviews]] system instead.


### Getting an instance of the Service API

We use [Wirebox](http://wiki.coldbox.org/wiki/WireBox.cfm) to auto wire our service layer. To inject an instance of the service API into your service objects and/or handlers, you can use wirebox's "inject" syntax as shown below:

```luceescript

// a handler example
component {
    property name="presideObjectService" inject="presideObjectService";

    function index( event, rc, prc ) {
        prc.eventRecord = presideObjectService.selectData( objectName="event", id=rc.id ?: "" );

        // ...
    }
}

// a service layer example
// (here at Pixl8, we prefer to inject constructor args over setting properties)
component {

    /**
     * @presideObjectService.inject presideObjectService
     */
     public any function init( required any presideObjectService ) {
        _setPresideObjectService( arguments.presideObjectService );

        return this;
     }

     public query function getEvent( required string id ) {
        return _getPresideObjectService().selectData(
              objectName = "event"
            , id         = arguments.id
        );
     }

     // we prefer private getters and setters for accessing private properties, this is our house style
     private any function _getPresideObjectService() {
         return variables._presideObjectService;
     }
     private void function _setPresideObjectService( required any presideObjectService ) {
         variables._presideObjectService = arguments.presideObjectService;
     }

}
```

### Using Auto Service Objects

An auto service object represents an individual data object. They are an instance of the given object that has been decorated with the service API CRUD methods.

Calling the CRUD methods works in the same way as with the main API with the exception that the objectName argument is no longer required. So:

```luceescript
record = presideObjectService.selectData( objectName="event", id=id );

// is equivalent to:
eventObject = presideObjectService.getObject( "event" );
record      = eventObject.selectData( id=id );
```

#### Getting an auto service object

This can be done using either the `getObject()` method of the Preside Object Service or by using a special Wirebox DSL injection syntax, i.e.

```luceescript
// a handler example
component {
    property name="eventObject" inject="presidecms:object:event";

    function index( event, rc, prc ) {
        prc.eventRecord = eventObject.selectData( id=rc.id ?: "" );

        // ...
    }
}

// a service layer example
component {

    /**
     * @eventObject.inject presidecms:object:event
     */
     public any function init( required any eventObject ) {
        _setPresideObjectService( arguments.eventObject );

        return this;
     }

     public query function getEvent( required string id ) {
        return _getEventObject().selectData( id = arguments.id );
     }

     // we prefer private getters and setters for accessing private properties, this is our house style
     private any function _getEventObject() {
         return variables._eventObject;
     }
     private void function _setEventObject( required any eventObject ) {
         variables._eventObject = arguments.eventObject;
     }

}
```

### CRUD Operations

The service layer provides core methods for creating, reading, updating and deleting records (see individual method documentation for reference and examples):

* [[presideobjectservice-selectdata]]
* [[presideobjectservice-insertdata]]
* [[presideobjectservice-updatedata]]
* [[presideobjectservice-deletedata]]

In addition to the four core methods above, there are also further utility methods for specific scanarios:

* [[presideobjectservice-dataexists]]
* [[presideobjectservice-selectmanytomanydata]]
* [[presideobjectservice-syncmanytomanydata]]
* [[presideobjectservice-getdenormalizedmanytomanydata]]
* [[presideobjectservice-getrecordversions]]
* [[presideobjectservice-insertdatafromselect]]


#### Specifying fields for selection

The [[presideobjectservice-selectdata]] method accepts a `selectFields` argument that can be used to specify which fields you wish to select. This can be used to select properties on your object as well as properties on related objects and any plain SQL aggregates or other SQL operations. For example:

```luceescript
records = newsObject.selectData(
    selectFields = [ "news.id", "news.title", "Concat( category.label, category$tag.label ) as catandtag"  ]
);
```

The example above would result in SQL that looked something like:

```sql
select      news.id
          , news.title
          , Concat( category.label, tag.label ) as catandtag

from        pobj_news     as news
inner join  pobj_category as category on category.id = news.category
inner join  pobj_tag      as tag      on tag.id      = category.tag
```

>>> The funky looking `category$tag.label` is expressing a field selection across related objects - in this case **news** -> **category** -> **tag**. See relationships, below, for full details.

#### Filtering data

All but the **insertData()** methods accept a data filter to either refine the returned recordset or the records to be updated / deleted. The API provides two arguments for filtering, `filter` and `filterParams`. Depending on the type of filtering you need, the `filterParams` argument will be optional.

##### Simple filtering

A simple filter consists of one or more strict equality checks, all of which must be true. This can be expressed as a simple CFML structure; the structure keys represent the object fields; their values represent the expected record values:

```luceescript
records = newsObject.selectData( filter={
      category             = chosenCategory
    , "category$tag.label" = "red"
} );
```

>>> The funky looking `category$tag.label` is expressing a filter across related objects - in this case **news** -> **category** -> **tag**. We are filtering news items whos category is tagged with a tag whose label field = "red".

##### Complex filters

More complex filters can be achieved with a plain SQL filter combined with filter params to make use of parametized SQL statements:

```luceescript
records = newsObject.selectData(
      filter       = "category != :category and DateDiff( publishdate, :publishdate ) > :daysold and category$tag.label = :category$tag.label"
    , filterParams = {
           category             = chosenCategory
         , publishdate          = publishDateFilter
         , "category$tag.label" = "red"
         , daysOld              = { type="integer", value=3 }
      }
);
```

>>> Notice that all but the *daysOld* filter param do not specify a datatype. This is because the parameters can be mapped to fields on the object/s and their data types derived from there. The *daysOld* filter has no field mapping and so its data type must also be defined here.

#### Making use of relationships

As seen in the examples above, you can use a special field syntax to reference properties in objects that are related to the object that you are selecting data from / updating data on. When you do this, the service layer will automatically create the necessary SQL joins for you.

The syntax takes the form: `(relatedObjectReference).(propertyName)`. The related object reference can either be the name of the related object, or a `$` delimited path of property names that navigate through the relationships (see examples below).

This syntax can be used in:

* Select fields
* Filters
* Order by statements
* Group by statements

To help with the examples, we'll illustrate a simple relationship between three objects:

```luceescript

// tag.cfc
component {}

// category.cfc
component {
    property name="category_tag" relationship="many-to-one" relatedto="tag"  required=true;
    property name="news_items"   relationship="one-to-many" relatedTo="news" relationshipKey="news_category";
    // ..
}

// news.cfc
component {
    property name="news_category" relationship="many-to-one" relatedto="category" required=true;
    // ..
}
```

##### Auto join example

```luceescript
// update news items whose category tag = "red"
presideObjectService.updateData(
      objectName = "news"
    , data       = { archived = true }
    , filter     = { "tag.label" = "red" } // the system will automatically figure out the relationship path between the news object and the tag object
);
```

##### Property name examples

```luceescript
// delete news items whose category label = "red"
presideObjectService.deleteData(
      objectName = "news"
    , data       = { archived = true }
    , filter     = { "news_category.label" = "red" }
);

// select title and category tag from all news objects, order by the category tag
presideObjectService.selectData(
      objectName   = "news"
    , selectFields = [ "news.title", "news_category$category_tag.label as tag" ]
    , orderby      = "news_category$category_tag.label"
);

// selecting categories with a count of news articles for each category
presideObjectService.selectData(
      objectName   = "category"
    , selectFields = [ "category.label", "Count( news_items.id ) as news_item_count" ]
    , orderBy      = "news_item_count desc"
);
```

>>>> While the auto join syntax can be really useful, it is limited to cases where there is only a single relationship path between the two objects. If there are multiple ways in which you could join the two objects, the system can have no way of knowing which path it should take and will throw an error.

#### Caching

By default, all [[presideobjectservice-selectData]] calls have their recordset results cached. These caches are automatically cleared when the data changes.

You can specify *not* to cache results with the `useCache` argument.

## Extending Objects

>>>>>> You can easily extend core data objects and objects that have been provided by extensions simply by creating `.cfc` file with the same name.

Objects with the same name, but from different sources, are merged at runtime so that you can have multiple extensions all contributing to the final object definition.

Take the `page` object, for example. You might write an extension that adds an **allow_comments** property to the object. That CFC would look like this:

```luceescript
// /extensions/myextension/preside-objects/page.cfc
component {
    property name="allow_comments" type="boolean" dbtype="boolean" required=false default=true;
}
```

After adding that code and reloading your application, you would find that the **psys_page** table now had an **allow_comments** field added.

Then, in your site, you may have some client specific requirements that you need to implement for all pages. Simply by creating a `page.cfc` file under your site, you can mix in properties along with the **allow_comments** mixin above:

```luceescript
// /application/preside-objects/page.cfc
component {
    // remove a property that has been defined elsewhere
    property name="embargo_date" deleted=true;

    // alter attributes of an existing property
    property name="title" maxLength="50"; // strict client requirement?!

    // add a new property
    property name="search_engine_boost" type="numeric" dbtype="integer" minValue=0 maxValue=100 default=0;
}
```

>>> To have your object changes reflected in GUI forms (i.e. the add and edit page forms in the example above), you will likely need to modify the form definitions for the object you have changed.

## Versioning

By default, Preside Data Objects will maintain a version history of each database record. It does this by creating a separate database table that is prefixed with `_version_`. For example, for an object named 'news', a version table named **_version_pobj_news** would be created.

The version history table contains the same fields as its twin as well as a few specific fields for dealing with version numbers, etc. All foreign key constraints and unique indexes are removed.

### Opting out

To opt out of versioning for an object, you can set the `versioned` attribute to **false** on your CFC file:

```luceescript
/**
 * @versioned false
 *
 */
component {
    // ...
}
```

### Interacting with versions

Various admin GUIs such as the :doc:`datamanager` implement user interfaces to deal with versioning records. However, if you find the need to create your own, or need to deal with version history records in any other way, you can use methods provided by the service api:

* [[presideobjectservice-getrecordversions]]
* [[presideobjectservice-getversionobjectname]]
* [[presideobjectservice-objectisversioned]]
* [[presideobjectservice-getnextversionnumber]]

In addition, you can specify whether or not you wish to use the versioning system, and also what version number to use if you are, when calling the [[presideobjectservice-insertData]], [[presideobjectservice-updateData]] and [[presideobjectservice-deleteData]] methods by using the `useVersioning` and `versionNumber` arguments.

Finally, you can select data from the version history tables with the [[presideobjectservice-selectdata]] method by using the `fromVersionTable`, `maxVersion` and `specificVersion` arguments.

### Many-to-many related data

By default, auto generated `many-to-many` data tables will be versioned along with your record changes. You can opt out of this by adding a `versioned=false` attribute to the `many-to-many` property:

```luceescript
property name="categories" relationship="many-to-many" relatedTo="category" versioned=false;
```

Inversely, you may have a `many-to-many` relationship for which you have an explicit join table that you'd like versioned along with the parent record. In this scenario, you can explicitly set `versioned=true`:

```luceescript
property name="categories" relationship="many-to-many" relatedTo="category" relatedVia="explicit_categories_obj" versioned=true;
```

### Ignoring changes

By default, when the data actually changes in your object, a new version will be created. If you wish certain fields to be ignored when it comes to determining whether or not a new version should be created, you can add a `ignoreChangesForVersioning` attribute to the property in the preside object.

An example scenario for this might be an object whose data is synced with an external source on a schedule. You may add a helper property to record the last sync check date, if no other fields have changed, you probably don't want a new version record being created just for that sync check date. In this case, you could do:

```luceescript
property name="_last_sync_check" type="date" dbtype="datetime" ignoreChangesForVersioning=true;
```

### Only create versions on update

As of **10.9.0**, you are able to specify that a version record is **not** created on **insert**. Instead, the first version record will be created on the first update to the record. This allows you to save on unnecessary version records in your database. To do this, add the `versionOnInsert=false` attribute to you object, e.g.

```luceescript
/**
 * @versioned       true
 * @versionOnInsert false
 */
component {
    // ...
}
```

## Organising data by sites

You can instruct the Preside Data Objects system to organise your objects' data into your system's individual sites (see [[workingwithmultiplesites]]). Doing so will mean that any data reads and writes will be specific to the currently active site.

To enable this feature for an object, simply add the `siteFiltered` attribute to the `component` tag:

```luceescript
/**
 * @siteFiltered true
 *
 */
component {
    // ...
}
```

>>>> As of Preside 10.8.0, this method is deprecated and you should instead use `@tenant site`. See [[data-tenancy]].
