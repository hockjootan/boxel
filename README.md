# Boxel Runtime

## Setup

- you will want the [Glint](https://marketplace.visualstudio.com/items?itemName=typed-ember.glint-vscode) vscode extension
- you will want the [vscode-glimmer](https://marketplace.visualstudio.com/items?itemName=chiragpat.vscode-glimmer) vscode extension
- you will want the [Playwright](https://marketplace.visualstudio.com/items?itemName=ms-playwright.playwright) vscode extension
- this project uses [volta](https://volta.sh/) for Javascript toolchain version management. Make sure you have the latest verison of volta on your system and have define [the ENV var described here](https://docs.volta.sh/advanced/pnpm).
- this project uses [pnpm](https://pnpm.io/) for package management. run `pnpm install` to install the project dependencies first.
- this project uses [docker](https://docker.com). Make sure to install docker on your system.

## Orientation

`packages/host` is the card runtime host application

`packages/realm-server` is a node app that serves the realm as an HTTP server, as well as, it can also host the runtime application for its own realm.

`packages/boxel-motion` is the animation primitives ember addon.

`packages/boxel-motion-test-app` is the test suite for boxel-motion

`packages/boxel-motion-demo-app` is the demo app for boxel-motion

`packages/matrix` is the docker container for running the matrix server: synapse, as well as tests that involve running a matrix client.

`packages/ai-bot` is a node app that runs a matrix client session and an OpenAI session. Matrix message queries sent to the AI bot are packaged with an OpenAI system prompt and operator mode context and sent to OpenAI. The ai bot enriches the OpenAI response and posts the response back into the matrix room.

## Running the Host App

There exists a "dev" mode in which we can use ember-cli to host the card runtime host application which includes live reloads. Additionally, you can also use the realm server to host the app, which is how it will be served in production.

### ember-cli Hosted App

In order to run the ember-cli hosted app:

1. `pnpm start` in the host/ workspace to serve the ember app. Note that this script includes the environment variable `OWN_REALM_URL=http://localhost:4201/draft/` which configures the host to point to the draft realm's cards realm by default.
2. `pnpm start:all` in the realm-server/ to serve the base realm, draft realm and published realm -- this will also allow you to switch between the app and the tests without having to restart servers)

The app is available at http://localhost:4200. It will serve the draft realm (configurable with OWN_REALM_URL, as mentioned above). You can open the base and draft cards workspace directly by entering http://localhost:4201/base or http://localhost:4201/draft in the browser (and additionally the published realm by entering http://localhost:4201/published).

When you are done running the app you can stop the synapse server by running the following from the `packages/matrix` workspace:

```
pnpm stop:synapse
```

### Realm server Hosted App

In order to run the realm server hosted app:

1. `pnpm start:build` in the host/ workspace to re-build the host app (this step can be omitted if you do not want host app re-builds)
2. `pnpm start:all` in the realm-server/ to serve the base, draft, and published realms

You can visit the URL of each realm server to view that realm's app. So for instance, the base realm's app is available at `http://localhost:4201/base` and the draft realm's app is at `http://localhost:4201/draft`.

Live reloads are not available in this mode, but you can just refresh the page to grab the latest code changes if you are running rebuilds (step #1 and #2 above).

#### Using `start:all`

Instead of running `pnpm start:base`, you can alternatively use `pnpm start:all` which also serves a few other realms on other ports--this is convenient if you wish to switch between the app and the tests without having to restart servers. Here's what is spun up with `start:all`:

| Port  | Description                                           | Running `start:all` | Running `start:base` |
| ----- | ----------------------------------------------------- | ------------------- | -------------------- |
| :4201 | `/base` base realm                                    | ✅                  | ✅                   |
| :4201 | `/drafts` draft realm                                 | ✅                  | 🚫                   |
| :4201 | `/published` draft realm                              | ✅                  | 🚫                   |
| :4202 | `/test` host test realm, `/node-test` node test realm | ✅                  | 🚫                   |
| :4203 | `root (/)` base realm                                 | ✅                  | 🚫                   |
| :4204 | `root (/)` drafts realm                               | ✅                  | 🚫                   |
| :4205 | qunit server mounting realms in iframes for testing   | ✅                  | 🚫                   |
| :8008 | Matrix synapse server                                 | ✅                  | 🚫                   |

#### Using `start:development`

You can also use `start:development` if you want the functionality of `start:all`, but without running the test realms. `start:development` will enable you to open http://localhost:4201 and allow to select between the cards in the /base and /demo realm.

### Card Pre-rendering

In order to support server-side rendered cards, this project incorporates FastBoot. By default `pnpm start` in the `packages/host` workspace will serve server-side rendered cards. Specifically, the route `/render?url=card_url&format=isolated` will serve pre-rendered cards. There is additional build overhead required to serve pre-rendered cards. If you are not working on the `/render` route in the host, then you would likely benefit from disabling FastBoot when starting up the host server so that you can have faster rebuilds. To do so, you can start the host server using:
`FASTBOOT_DISABLED=true pnpm start`.

The realm server also uses FastBoot to pre-render card html. The realm server boots up the host app in a FastBoot container. The realm server will automatically look for the host app's `dist/` output to use when booting up the infrastructure for pre-rendering cards. Make sure to start to the host app first before starting the realm server so that the host app's `dist/` output will be generated. If you are making changes that effect the `/render` route in the host app, you'll want to restart the host app (or run `pnpm build`) in order for the realm server to pick up your changes.

### Matrix Server

The boxel platform leverages a Matrix server called Synapse in order to support identity, workflow, and chat behaviors. This project uses a dockerized Matrix server. We have multiple matrix server configurations (currently one for development that uses a persistent DB, and one for testing that uses an in-memory DB). You can find and configure these matrix servers at `packages/matrix/docker/synapse/*`.

This server is automatically started as part of the `pnpm start:all` script, but if you wish to control it separately, from `packages/matrix`, execute:

```
pnpm start:synapse
```

The local Matrix server will be running at `http://localhost:8008`.

To stop the matrix server, from `packages/matrix`, execute:

```
pnpm stop:synapse
```

#### Matrix Administration

Matrix administration requires an administrative user and a special client in order to use. Matrix administration is used for creating users, creating rooms, creating registration tokens, managing media, viewing events, etc. Note that you will need to use the matrix administration UI to create tokens to register new matrix users.

First you must create an administrative user:

1. start the matrix server `pnpm start:synapse`
2. run a script to create an administrative user:
   ```
   docker exec -it boxel-synapse register_new_matrix_user http://localhost:8008 -c /data/homeserver.yaml -u admin -p your_admin_password --admin
   ```
3. Run the docker container:
   ```
   docker run --name synapse-admin -p 8080:80 -d awesometechnologies/synapse-admin
   ```

After you have created an administrative user and have created the docker container you can start the admin console by executing the following in the packages/matrix workspace:

```
pnpm start:admin
```

Then visit `http://localhost:8080`, and enter the admin user's username (`admin`) and the password, also enter in your matrix server url `http://localhost:8008` in the homeserver URL field, and click "Signin".

Note you can use this same administrative interface to login to the staging and production matrix server. The credentials are available in AWS secrets manager.

To stop the admin console run the following in the packages/matrix workspace:

```
pnpm stop:admin
```

## Boxel UI Component Explorer

There is a ember-freestyle component explorer available to assist with development. In order to run the freestyle app:

1. `cd packages/boxel-ui`
2. `pnpm start`
3. Visit http://localhost:4210/ in your browser

## Boxel Motion Demo App

In order to run the boxel-motion demo app:

1. `cd packages/boxel-motion-demo-app`
2. `pnpm start`
3. Visit http://localhost:4200 in your browser

## Running the Tests

There are currently 5 test suites:

### Host

To run the `packages/host/` workspace tests start the following servers:

1. `pnpm start:all` in the `packages/realm-server/` to serve _both_ the base realm and the realm that serves the test cards
2. `pnpm start` in the `packages/host/` workspace to serve ember

The tests are available at `http://localhost:4200/tests`

### Realm Server Node tests

First make sure to generate the host app's `dist/` output in order to support card pre-rendering by first starting the host app (instructions above). If you want to make the host app's `dist/` output without starting the host app, you can run `pnpm build` in the host app's workspace.

To run the `packages/realm-server/` workspace tests start:

1. `pnpm start:all` in the `packages/realm-server/` to serve _both_ the base realm and the realm that serves the test cards for node.
2. Run `pnpm test` in the `packages/realm-server/` workspace to run the realm node tests

### Realm Server DOM tests

This test suite contains acceptance tests for asserting that the Realm server is capable of hosting its own app. To run these tests in the browser execute the following in the `packages/realm-server` workspace:

1. `pnpm start:all`

Visit `http://localhost:4205` after the realms have finished starting up

### Boxel Motion

1. `cd packages/boxel-motion-test-app`
2. `pnpm test` (or `pnpm start` and visit http://localhost:4200/tests to run tests in the browser)

### Matrix tests

This test suite contains tests that exercise matrix functionality. These tests are located at `packages/matrix/tests`, and are executed using the [Playwright](https://playwright.dev/) test runner. To run the tests from the command line, first make sure that the matrix server is not already running. You can stop the matrix server by executing the following from `packages/matrix`

```
pnpm stop:synapse
```

The matrix client relies upon the host app and the realm servers. Start the host app from the `packages/host` folder:

```
pnpm start
```

Then start the realm server (minus the matrix server). From the `packages/realm-server` folder:

```
pnpm start:without-matrix
```

Then to run the tests from the CLI execute the following from `packages/matrix`:

```
pnpm start:test
```

Alternatively you can also run these tests from VS Code using the VS Code Playwright plugin (which is very strongly recommended). From the "test tube" icon, you can click on the play button to run a single test or all the tests.

![Screenshot_20230427_161250](https://user-images.githubusercontent.com/61075/234980198-fe049b61-917d-4dc8-a9eb-ddc54b36b160.png)

or click on the play button in the left margin next to the test itself to run a test:
![Screenshot_20230428_150147](https://user-images.githubusercontent.com/61075/235231663-6fabfc41-8294-4674-adf1-f3793b83e516.png)

you can additionally set a breakpoint in code, and playwright will break at the breakpoint.
