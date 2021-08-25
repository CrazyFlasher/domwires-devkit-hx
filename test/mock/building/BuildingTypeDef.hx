package mock.building;

@Model typedef BuildingTypeDef =
{
    > mock.gameObject.GameObjectTypeDef,

    final maxUnits:Int;
    final creationTime:Int;
}
