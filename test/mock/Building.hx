package mock;

@Model typedef Building =
{
    > mock.GameObject,

    final maxUnits:Int;
    final creationTime:Int;
}
