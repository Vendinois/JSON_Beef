using System;
using System.Collections;
using JSON_Beef;

namespace JSON_Beef_Test
{
	[Serializable]
	public class Person
	{
		public String FirstName;
		public String LastName;

		[IgnoreSerialize]
		public int Age;
	}

	[Serializable]
	public class Author: Person
	{
		public List<Book> Books = new List<Book>() ~ DeleteContainerAndItems!(_);
		public List<String> Publishers = new List<String>() ~ delete _;

		public this(String firstName = "", String lastName = "", int age = 0)
		{
			FirstName = firstName;
			LastName = lastName;
			Age = age;
		}
	}

	[Serializable]
	public class Book
	{
		public String Name;

		public this(String name = "")
		{
			Name = name;
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
