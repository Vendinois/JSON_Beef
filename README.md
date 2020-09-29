# JSON_Beef
A JSON parser library made in the Beef programming language.

This is still a work in progress and was kind of implemented roughly to get a grasp of Beef at the same type. So major refactoring and potential breaking changes can occure in the future, though I will try to keep that as the bare minimum.

## Summary
- [Project Organization](#project-organization)
- [Adding JSON_Beef to your project](#Adding-JSON_Beef-to-your-project)
- [Using the library](#Using-the-library)
- [Important notes](#Important-notes)
- [Todo](#Todo)

## Project organization
This repository consist of two distinct folders:
- JSON_Beef_Test: A program to test the objects and methods from the JSON_Beef lib.
- lib: The JSON_Beef library.

The JSON_Beef_Test program depends on the Beef Extensions Library that can be found here: [Beef Extensions Library](https://github.com/Jonathan-Racaud/Beef-Extensions-Lib).

## Adding JSON_Beef to your project
1. Clone the Beef Extensions Library in the location of your choice.
2. Clone the JSON_Beef library in the location of your choice.
3. In Beef IDE, right click on Workspace->Add existing project.
4. Select the BeefProj.toml file ffrom the JSON_Beef project.
5. Repeat step 3 and 4 for the Beef Extensions Library.
6. Open your project's properties.
7. Go to General->Dependencies
8. Tick JSON_Beef (you can also tick Beef Extensions Library, but it should be added as dependencies automatically when building).
9. You can now start using the library.


## Using the library
JSON_Beef consists of several objects to manipulate JSON data:
- JSONParser: Used to validate and parse a JSON String into either a **JSONObject** or a **JSONArray**
- JSONObject: Class representing a JSON Object.
- JSONArray: Class representing a JSON Array.
- JSONValidator: Class implementing the JSON specification validation rules.
- JSONUtil: Utility class for working with certain aspect of the JSON specification.
- JSONSerializer: Class serializing an Object into either a **JSONObject** a **JSONArray** or **String** object.
- JSONDeserializer: Class deserializing a JSON String into an Object of the specified type **(Work in progress)**

**Validating a JSON String:**
```c#
JSONValidator.IsValidJson(jsonString);
```

**Parsing a JSON String into a JSONArray:**
```c#
if (JSONValidator.IsValidJson(data) && (JSONParser.GetJsonType(data) == .ARRAY))
{
    let array = JSONParser.ParseArray(data);

    // Work with the JSONArray object.

    // You are responsible for the deletion of the JSONArray.
    delete array.Get();
}
```

**Parsing a JSON String into a JSON Object:**
```c#
if (JSONValidator.IsValidJson(data) && (JSONParser.GetJsonType(data) == .OBJECT))
{
    let array = JSONParser.ParseObject(data);

    // Work with the JSONAObject object.

    // You are responsible for the deletion of the JSONObject.
    delete array.Get();
}
```

**Serializing a user defined class:**
Serializing a user defined class uses reflection so in order for it to work, you must declare your class like so:
```c#
// Allows for the type to be created via reflection (used by the Deserializer).
[AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]

// Allows for the type's fields to be discoverable via reflection in order to serialize them.
[Reflect]
public class CustomClass
{
    // public fields will be automatically serialized.
    public String Name;

    // This attributes allows for ignoring fields.
    [IgnoreSerialize]
    public String IgnoredField;

    // Private fields are ignored.
    private int mRandomId;
}
```

You can then use the JSONSerializer class like so:
```c#
let jsonObject = JSONSerializer.Serialize<JSONObject>(object);
let jsonArray = JSONSerializer.Serialize<JSONArray>(object);
let str = JSONSerializer.Serialize<String>(object);
```

**Deserializing a user defined class:**
In order to deserialize a user defined type, it must be marked with the following attributes:
```c#
// Allows for the type to be created via reflection (used by the Deserializer).
[AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]

// Allows for the type's fields to be discoverable via reflection in order to serialize them.
[Reflect]
```

Now you can deserialize a JSON string into your CustomClass using JSONDeserializer:
```c#
let customClass = scope CustomClass();
let res = JSONDeserializer.Deserialize<CustomClass>(json, customClass);
// The CustomClass objects will be the target of the deserialization
```

Because the Deserialize process needs to allocate memory for the reference type fields of the target object, you need to be sure to delete the fields at the appropriate time to avoid any memory leaks.

For more examples about how to use the library you can look at the JSON_Beef_Test project.

## Important notes
- For the moment, when deserializing into a user defined type, the keys inside the JSON object string representation must match the field's name as declared (case sensitive):

```c#
public class Person
{
    public String FirstName;
}

let wrongJson = "{\"Firstname\": \"Jonathan\"}";
let person = scope Person();
JSONDeserialize<Person>(wrongJson, person); // return: Error

let rightJson = "{\"FirstName\": \"Jonathan\"}";
let person = scope Person();
JSONDeserialize<Person>(rightJson, person); // return: Ok
```

- Deserializing/Serializing struct types do not work well. The reason being with instantiating at runtime using reflection struct types.

## Todo
- JSON String parsing:
  - Handle unescaped characters in strings as error.
  - Parse UTF-8 characters e.g.: u0063.
- Reflection based Object deserialization:
  - Handle Dictionary types.
  - Handle properties.
