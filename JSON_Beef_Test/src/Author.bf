using System;
using System.Collections;
using JSON_Beef.Attributes;

namespace JSON_Beef_Test
{
	[AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
	[Reflect]
	public class Person
	{
		public String FirstName = null ~ delete _;
		public String LastName = null ~ delete _;

		[IgnoreSerialize]
		public int Age;
	}

	[AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
	[Reflect]
	public class Author: Person
	{
		public int Id;
		public float Test;
		public bool Known;
		public List<Book> Books = null ~ DeleteContainerAndItems!(_);
		public List<String> Publishers = null ~ DeleteContainerAndItems!(_);
	}

	[AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
	[Reflect]
	public class Book
	{
		public String Name = null ~ delete _;

		public this()
		{

		}

		public this(String name)
		{
			Name = new String(name);
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
