# Agar.io Updater

This project utilizes static analysis of the minified JavaScript game client files for the popular Massively Multiplayer HTML5 game: [agar.io](http://agar.io/).

The purpose of this package is to aid in reverse engineering and modding of the game client regardless of the current client revision. Since the game updates multiple times per week, it is important to have tooling that automatically outputs transformed JavaScript that is readable by humans.

## Setup

1. Clone this repo
2. `cd` into the cloned repo's directory
3. `$ npm install`
4. `$ npm install -g coffee-script`
5. `$ cp config-sample.json config.json`
6. `$ coffee updater.coffee`

