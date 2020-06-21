using System;
using System.Collections;
using JSON_Beef;

namespace JSON_Beef_Test
{
	[AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
	[Reflect]
	public class Person
	{
		public String FirstName;
		public String LastName;

		[IgnoreSerialize]
		public int Age;
	}

	[AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
	[Reflect]
	public class Author: Person
	{
		public JsonList<Book> Books = new JsonList<Book>() ~ DeleteContainerAndItems!(_);
		public JsonList<String> Publishers = new JsonList<String>() ~ delete _;

		public this(String firstName = "", String lastName = "", int age = 0)
		{
			FirstName = firstName;
			LastName = lastName;
			Age = age;
		}
	}

	[AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
	[Reflect]
	public class Book
	{
		public String Name;

		public this(String name = "Book")
		{
			Name = name;
		}

		public void Test()
		{

		}

		public static bool operator==(Book a, Book b)
		{
			return a.Name.Equals(b.Name);
		}

		public static bool operator!=(Book a, Book b)
		{
			return !(a == b);
		}
	}
}
