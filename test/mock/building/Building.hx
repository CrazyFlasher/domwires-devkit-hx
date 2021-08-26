package mock.building;

@Model typedef Building =
{
    > mock.gameObject.GameObject,

    final maxUnits:Int;
    final creationTime:Int;
}
