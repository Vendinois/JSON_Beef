using System;
using System.Collections;

namespace JSON_Beef
{
	// This class exists because the List<T> class doesn't have reflection for its methods
	// so it is impossible for the moment to invoke the Add method when deserializing a string into an object.
	[AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
	[Reflect]
	[Obsolete("Use case no longer exists, can be swapped by the List<T> type.", false)]
	public class JsonList<T> : List<T>
	{
		// The Add method is overridden only to make it available when using reflection.
		new public void Add(T item)
		{
			base.Add(item);
		}
	}
}
