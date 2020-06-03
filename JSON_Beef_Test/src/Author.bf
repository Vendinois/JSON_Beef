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
	}

	[Serializable]
	public class Author: Person
	{
		//public List<Book> Books = new List<Book>() ~ DeleteContainerAndItems!(_);
		public List<List<String>> Publishers = new List<List<String>>() ~ DeleteContainerAndItems!(_);

		[IgnoreSerialize]
		public int Age;

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
		public List<List<String>> Publishers = new List<List<String>>() ~ DeleteContainerAndItems!(_);

		public this(String name)
		{
			Name = name;
		}
	}
}
