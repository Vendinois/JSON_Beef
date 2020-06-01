namespace System.Reflection
{
	extension FieldInfo
	{
		public bool HasFieldFlag(FieldFlags flag)
		{
			return (*mFieldData).mFlags == flag;
		}
	}
}
