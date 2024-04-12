minetest.register_node("city:tree_a", {
    description = "Tree",
    tiles = {"city_tree_c_transparent.png"},--city.load_material("city", "city_tree_b.mtl"),
    drawtype = "mesh",
    paramtype = "light",
    mesh = "city_tree_c.obj",
    groups = {replaceable=1},
    pointable = false,
})