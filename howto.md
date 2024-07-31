## Starting the World in Minetest

The world currently used for a custom project with InstaBuilder is named hdbg_world and is stored in my minetest world folder.

during development is stored in a directory separate from the project. This is used for packaging the distribution.

Here is the call I issue to start Minetest with the current world:



minetest --go --world '/Users/admin/Documents/Projects/Minetest/game-projects/hdbg_zip_deliveries/InstaBuilder/worlds/world' &

Alternatively I copied this world to the common minetest worlds directory


## Packaging for Distribution

I prepare all distribution versions for the current client in a directory separate from the project at this path:

`/Users/admin/Documents/Projects/Minetest/game-projects/hdbg_zip_deliveries/`

The world currently used for a custom project with InstaBuilder is named hdbg_world and is stored in my minetest world folder. This world should be included in the distribution. Hence whenever I change the worls I have to copy it to the current delivery folder before I zip and distribute that:

`cp -R /Users/admin/Library/Application\ Support/minetest/worlds/ /Users/admin/Documents/Projects/Minetest/game-projects/hdbg_zip_deliveries/InstaBuilder/worlds/hdbg_world`
