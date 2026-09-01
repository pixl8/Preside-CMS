# Preside Data Objects (ORM)

Preside Objects are CFC files in `/preside-objects/` that define database tables and get an automatic CRUD service. No traditional Hibernate ORM is used.

## Basic Object Definition

```cfml
// /preside-objects/blog_post.cfc
/**
 * @labelfield title
 */
component {
    property name="title"       type="string"  dbtype="varchar"  maxLength="200" required=true;
    property name="slug"        type="string"  dbtype="varchar"  maxLength="200" required=true uniqueindexes="slug";
    property name="body"        type="string"  dbtype="text";
    property name="published"   type="boolean" dbtype="boolean"  default=false;
    property name="publish_date" type="date"   dbtype="datetime";
    property name="author"      relationship="many-to-one" relatedTo="security_user";
    property name="categories"  relationship="many-to-many" relatedTo="blog_category";
}
```

Table is automatically created/synced as `pobj_blog_post`. Four properties are always auto-added:
- `id` (varchar 35, UUID, PK)
- `label` (varchar 250) — driven by `@labelfield`
- `datecreated` (datetime)
- `datemodified` (datetime)

## Property Attributes

| Attribute | Description |
|-----------|-------------|
| `name` | Field name (required) |
| `type` | CFML type: `string`, `numeric`, `boolean`, `date` |
| `dbtype` | DB column type: `varchar`, `int`, `text`, `boolean`, `datetime`, `decimal`, `bigint` |
| `maxLength` | Required for varchar fields |
| `required` | NOT NULL constraint |
| `default` | Static value, or `cfml:Now()`, or `method:myMethod` |
| `indexes` | e.g. `"idx1,idx2|1"` (compound: `"slug|1"` + `"slug_parent|2"`) |
| `uniqueindexes` | Unique constraint |
| `control` | Form control: `textinput`, `textarea`, `richeditor`, `select`, etc. |
| `renderer` | Content renderer name |
| `formula` | SQL formula for computed field |
| `generator` | Auto-value: `UUID`, `slug`, `timestamp`, `nextint`, `hash`, `method:myFunc` |
| `generate` | When: `insert`, `always`, `never` |
| `generateFrom` | Source property for slug generator |
| `enum` | Enum type defined in `settings.enum.myType` |
| `feature` | Only include if feature enabled |
| `cloneable` | Include in cloning (default: true for most fields) |
| `autoTrim` | Trim on save |
| `ignoreChangesForVersioning` | Don't version this field's changes |

## Component Annotations

```cfml
/**
 * @labelfield              title
 * @nolabel                 true          // No label field
 * @tablename               custom_name   // Override table name
 * @tableprefix             myapp_        // Override prefix
 * @versioned               false         // Disable versioning
 * @versionOnInsert         false         // Don't version on insert
 * @feature                 myFeature
 * @defaultFilters          activeOnly    // Always apply these saved filters
 * @datamanagerEnabled      true
 * @datamanagerGridFields   id,title,datecreated
 * @datamanagerDefaultSortOrder title asc
 * @datamanagerAllowedOperations read,add,edit,delete,clone
 * @datamanagerGroup        mygroup       // Group in Data Manager nav
 * @cloneable               true
 * @labelRenderer           myRenderer
 * @tenant                  site          // Data tenancy
 */
component { ... }
```

## Relationships

### Many-to-One (FK column in this table)
```cfml
property name="category" relationship="many-to-one" relatedTo="blog_category" required=true;
```
Creates `category` varchar(35) FK column in this table.

### One-to-Many (no column here, traverse the other side)
```cfml
// On blog_category.cfc:
property name="posts" relationship="one-to-many" relatedTo="blog_post" relationshipKey="category";
```

### Many-to-Many (auto pivot table)
```cfml
property name="categories" relationship="many-to-many" relatedTo="blog_category";
// Creates pivot table: pobj_blog_post__join__blog_category

// Custom pivot table name:
property name="tags" relationship="many-to-many" relatedTo="tag" relatedVia="post_tags";

// Multiple M2M to same object — must use relatedVia:
property name="primary_tags"   relationship="many-to-many" relatedTo="tag" relatedVia="post_primary_tags";
property name="secondary_tags" relationship="many-to-many" relatedTo="tag" relatedVia="post_secondary_tags";
```

### SelectData View Relationship (v10.11.0+)
```cfml
property name="active_posts" relationship="select-data-view" relatedTo="activeBlogPosts" relationshipKey="category";
```

## CRUD Service API

Inject the object DAO directly, or use `presideObjectService`:

```cfml
// Direct DAO injection (preferred)
property name="blogPostDao" inject="presidecms:object:blog_post";

// Or via service
property name="presideObjectService" inject="presideObjectService";

// selectData
var posts = blogPostDao.selectData(
      selectFields = [ "id", "title", "category.label as cat_name", "Count(comments.id) as comment_count" ]
    , filter       = { published=true }
    , orderBy      = "publish_date desc"
    , maxRows      = 10
    , startRow     = 1
    , useCache     = true
    , groupBy      = "id"
);

// insertData — returns new record ID
var newId = blogPostDao.insertData( data={
      title    = "My Post"
    , body     = "Content here"
    , author   = authorId
    , categories = [ cat1Id, cat2Id ]   // M2M as array
});

// updateData
blogPostDao.updateData(
      data   = { title="Updated Title", published=true }
    , filter = { id=postId }
);

// deleteData
blogPostDao.deleteData( id=postId );
// or: blogPostDao.deleteData( filter={ published=false } );

// dataExists
var exists = blogPostDao.dataExists( filter={ slug="my-post" } );

// selectCount
var total = blogPostDao.selectData( selectFields=["Count(*) as total"] ).total;
```

## Filtering

### Simple struct filter
```cfml
blogPostDao.selectData( filter={ published=true, author=authorId } );
```

### SQL filter with params
```cfml
blogPostDao.selectData(
      filter       = "published = :published and publish_date > :minDate"
    , filterParams = {
          published = { type="bit", value=true }
        , minDate   = { type="timestamp", value=Now() }
      }
);
```

### Cross-relationship filter (dot notation)
```cfml
// Filter by related object field
blogPostDao.selectData( filter={ "category.active"=true } );

// Multi-level
blogPostDao.selectData( filter={ "category$parent.featured"=true } );
```

### Extra filters (array of filter structs)
```cfml
blogPostDao.selectData(
    extraFilters = [
          { filter={ published=true } }
        , { filter="publish_date > :now", filterParams={ now=Now() } }
    ]
);
```

### Named (saved) filters
Defined in `Config.cfc`:
```cfml
settings.filters.publishedPosts = {
      filter       = "published = :published and publish_date <= :now"
    , filterParams = { published=true, now=Now() }
};
// Or as a function:
settings.filters.publishedPosts = function( args={}, cbController ) {
    return { filter={ published=true } };
};
```
Or in `/handlers/DataFilters.cfc`:
```cfml
component {
    private struct function publishedPosts( event, rc, prc, args={} ) {
        return { filter={ published=true } };
    }
}
```
Use:
```cfml
blogPostDao.selectData( savedFilters=["publishedPosts"] );
```

### Default filters (always applied)
```cfml
/** @defaultFilters publishedPosts,activeOnly */
component { ... }

// Bypass:
blogPostDao.selectData( ignoreDefaultFilters=["publishedPosts"] );
```

## Select Fields & Formulas

```cfml
// Simple fields
selectFields = [ "id", "title" ]

// Cross-relationship (join traversal)
selectFields = [ "category.label as cat_label", "author.display_name as author_name" ]

// Aggregate
selectFields = [ "Count(comments.id) as comment_count", "Max(comments.datecreated) as last_comment" ]

// Formula property (defined on object)
property name="full_name"      formula="Concat(${prefix}first_name, ' ', ${prefix}last_name)";
property name="comment_count"  formula="agg:count{ comments.id }";
property name="latest_comment" formula="agg:max{ comments.datecreated }";
```

## Versioning

By default all objects are versioned. Version tables are named `_version_pobj_objectname`.

```cfml
// Disable versioning entirely:
/** @versioned false */
component { ... }

// Disable version on insert only:
/** @versioned true @versionOnInsert false */
component { ... }

// Don't version a specific field's changes:
property name="_last_sync" ignoreChangesForVersioning=true;

// M2M versioning (default: not versioned)
property name="tags" relationship="many-to-many" relatedTo="tag" versioned=true;

// Get versions
var versions = presideObjectService.getRecordVersions( objectName="blog_post", id=postId );
```

## Cloning

```cfml
/** @cloneable true */
component { ... }

// Custom clone handler
/** @cloneHandler myCloner */
component { ... }

// /handlers/ObjectCloners/MyCloner.cfc
component {
    function clone( objectName, recordId, data={} ) {
        // return new record ID
    }
}
```

## SelectData Views (v10.11.0+)

Named queries for reuse across the codebase:

```cfml
// /handlers/SelectDataViews.cfc
component {
    private struct function activeBlogPosts( event, rc, prc ) {
        return {
              objectName   = "blog_post"
            , filter       = { published=true }
            , selectFields = [ "id", "title", "category" ]
            , orderBy      = "publish_date desc"
        };
    }
}

// Use:
var posts = presideObjectService.selectView( "activeBlogPosts" );

// Reference as relationship:
property name="active_posts" relationship="select-data-view" relatedTo="activeBlogPosts" relationshipKey="category";
```

## Data Tenancy (v10.8.0+)

Automatically scope data by a tenant (e.g. customer, site):

```cfml
// Config.cfc
settings.tenancy.customer = {
      object    = "customer"
    , defaultFk = "customer"
};

// Apply to object:
/** @tenant customer */
component { ... }

// Tenant ID provider:
// /handlers/tenancy/customer.cfc
component {
    private string function getId( event, rc, prc ) {
        return customerService.getCurrentCustomerId();
    }
}

// Bypass tenancy:
dao.selectData( bypassTenants=["customer"] );

// Use alternative tenant:
dao.selectData( tenantIds={ customer=otherCustomerId } );
```

## Label Renderers (v10.8.0+)

Custom display for object pickers:

```cfml
/** @labelRenderer session_category */
component { ... }

// /handlers/renderers/labels/session_category.cfc
component {
    private array function _selectFields( event, rc, prc ) {
        return [ "label", "colour" ];
    }
    private string function _orderBy( event, rc, prc ) { return "label"; }
    private string function _renderLabel( event, rc, prc ) {
        return '<i style="background:#arguments.colour#"></i> #HtmlEditFormat(arguments.label)#';
    }
}
```

## Data Exporters (v10.8.7+)

```cfml
// Enable:
settings.features.dataexport.enabled = true;

// On object:
/**
 * @dataExportFields id,title,category,datecreated
 * @dataExportExpandManytoOneFields true
 */
component { ... }

// Custom exporter handler: /handlers/dataExporters/MyFormat.cfc
/**
 * @exportFileExtension myext
 * @exportMimeType      application/x-myformat
 */
component {
    private string function export( selectFields, fieldTitles, batchedRecordIterator, meta ) {
        // return file path
    }
}
```

## Object Extension (Merging)

Objects with the same name across core/extensions/application are merged at runtime:

```cfml
// /application/preside-objects/page.cfc
// Adds to the core page object:
component {
    property name="custom_field" type="string" dbtype="varchar" maxlength="100";
    property name="old_field"    deleted=true;           // remove a property
    property name="title"        maxLength="50";         // override attribute
}
```

## ENUM Properties

```cfml
// Config.cfc
settings.enum.statusType = [ "draft", "published", "archived" ];

// Object
property name="status" enum="statusType" type="string" dbtype="varchar" maxlength="20";

// i18n/enum/statusType.properties:
// draft.label=Draft
// published.label=Published
```

## Generated Fields

```cfml
property name="slug"      generator="slug"      generateFrom="title" generate="insert";
property name="unique_id" generator="UUID"       generate="insert";
property name="updated"   generator="timestamp" generate="always";
property name="seq"       generator="nextint"   generate="insert";
property name="my_hash"   generator="method:calculateHash" generate="always";
```

## DB Sync Behaviour

- New properties → new columns added
- Removed properties → column renamed to `_deprecated_fieldname`
- Tables never deleted when objects removed
- Adding required field to existing data → exception (use DB migration scripts)
