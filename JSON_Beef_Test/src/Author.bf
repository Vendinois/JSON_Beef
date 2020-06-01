using System;
using JSON_Beef;

namespace JSON_Beef_Test
{
	[Serializable]
	public class Author
	{
		public String FirstName;
		public String LastName;
		public Book Book = new Book();
		private int id;

		[IgnoreSerialize]
		public int Age;

		public this(String firstName = "", String lastName = "", int age = 0)
		{
			FirstName = firstName;
			LastName = lastName;
			Age = age;
		}

		public ~this()
		{
			delete Book;
		}
	}

	[Serializable]
	public class Book
	{
		public String Name;
	}
}
