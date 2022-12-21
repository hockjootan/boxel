import { module, test } from 'qunit';
import { Loader } from '@cardstack/runtime-common/loader';
import { Realm } from '@cardstack/runtime-common/realm';
import { Deferred } from '@cardstack/runtime-common/deferred';
import { baseRealm, LooseSingleCardDocument } from '@cardstack/runtime-common';
import {
  testRealmURL,
  setupCardLogs,
  TestRealmAdapter,
  TestRealm,
  cleanWhiteSpace,
} from '../../helpers';
import { setupRenderingTest } from 'ember-qunit';
import type LoaderService from '@cardstack/host/services/loader-service';
import type WorkerRenderer from '@cardstack/host/services/worker-renderer';

module('Integration | worker-renderer', function (hooks) {
  let service: WorkerRenderer;
  let adapter: TestRealmAdapter;
  let realm: Realm;
  let staticResponses: Map<string, string>;
  setupRenderingTest(hooks);
  setupCardLogs(
    hooks,
    async () => await Loader.import(`${baseRealm.url}card-api`)
  );

  hooks.beforeEach(async function () {
    Loader.addURLMapping(
      new URL(baseRealm.url),
      new URL('http://localhost:4201/base/')
    );
    let loader = (this.owner.lookup('service:loader-service') as LoaderService)
      .loader;

    adapter = new TestRealmAdapter({});
    realm = await TestRealm.createWithAdapter(adapter, this.owner);
    loader.registerURLHandler(new URL(realm.url), realm.handle.bind(realm));
    await realm.ready;

    await realm.write(
      'pet.gts',
      `
      import { contains, field, Component, Card } from "https://cardstack.com/base/card-api";
      import StringCard from "https://cardstack.com/base/string";

      export class Pet extends Card {
        @field firstName = contains(StringCard);
        static isolated = class Isolated extends Component<typeof this> {
          <template>
            <h3><@fields.firstName/></h3>
          </template>
        }
      }
    `
    );
    await realm.write(
      'Pet/mango.json',
      JSON.stringify({
        data: {
          type: 'card',
          id: `${testRealmURL}Pet/mango`,
          attributes: {
            firstName: 'Mango',
          },
          meta: {
            adoptsFrom: {
              module: `${testRealmURL}pet`,
              name: 'Pet',
            },
          },
        },
      } as LooseSingleCardDocument)
    );
    await realm.write(
      'Pet/vangogh.json',
      JSON.stringify({
        data: {
          type: 'card',
          id: `${testRealmURL}Pet/vangogh`,
          attributes: {
            firstName: 'Van Gogh',
          },
          meta: {
            adoptsFrom: {
              module: `${testRealmURL}pet`,
              name: 'Pet',
            },
          },
        },
      } as LooseSingleCardDocument)
    );

    // the staticResponses map emulates how the current-run requests a visit.
    // there is a good chance this will change as we refactor the current-run
    staticResponses = new Map();
    {
      let result = await realm.searchIndex.card(
        new URL(`${testRealmURL}Pet/mango`)
      );
      if (!result || result.type === 'error') {
        throw new Error(
          `bug: cannot setup realm correctly, expected instance ${testRealmURL}Pet/mango does not exist or has errors`
        );
      }
      staticResponses.set(
        `${testRealmURL}Pet/mango`,
        JSON.stringify(result.doc, null, 2)
      );
    }
    {
      let result = await realm.searchIndex.card(
        new URL(`${testRealmURL}Pet/vangogh`)
      );
      if (!result || result.type === 'error') {
        throw new Error(
          `bug: cannot setup realm correctly, expected instance ${testRealmURL}Pet/vangogh does not exist or has errors`
        );
      }
      staticResponses.set(
        `${testRealmURL}Pet/vangogh`,
        JSON.stringify(result.doc, null, 2)
      );
    }

    service = this.owner.lookup(
      'service:worker-renderer'
    ) as WorkerRenderer;

    // // This emulates the application.hbs
    // await renderComponent(
    //   class TestDriver extends GlimmerComponent {
    //     <template>
    //       <template shadowroot="open">
    //         <WorkerRender/>
    //       </template>
    //     </template>
    //   }
    // );
  });

  test("can generate the card's rendered HTML", async function (assert) {
    {
      let deferred = new Deferred<string>();
      await service.visit(
        `/render?url=${encodeURIComponent(
          testRealmURL + 'Pet/mango'
        )}&format=isolated`,
        staticResponses,
        (html: string) => deferred.fulfill(html)
      );
      let html = await deferred.promise;
      assert.strictEqual(
        cleanWhiteSpace(html),
        cleanWhiteSpace(`
          <!--Server Side Rendered Card HTML START-->
          <div data-test-shadow-component="">
            <h3> Mango </h3>
          </div>
          <!--Server Side Rendered Card HTML END-->
        `),
        'the pre-rendered HTML is correct'
      );
    }
    // Testing thru a re-render
    {
      let deferred = new Deferred<string>();
      await service.visit(
        `/render?url=${encodeURIComponent(
          testRealmURL + 'Pet/vangogh'
        )}&format=isolated`,
        staticResponses,
        (html: string) => deferred.fulfill(html)
      );
      let html = await deferred.promise;
      assert.strictEqual(
        cleanWhiteSpace(html),
        cleanWhiteSpace(`
          <!--Server Side Rendered Card HTML START-->
          <div data-test-shadow-component="">
            <h3> Van Gogh </h3>
          </div>
          <!--Server Side Rendered Card HTML END-->
        `),
        'the pre-rendered HTML is correct'
      );
    }
  });
});
