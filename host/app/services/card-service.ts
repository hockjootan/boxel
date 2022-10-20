import Service, { service } from '@ember/service';
import { stringify } from 'qs';
import LoaderService from './loader-service';
import LocalRealm from '../services/local-realm';
import {
  type LooseSingleCardDocument,
  isSingleCardDocument,
  isCardCollectionDocument,
  type Card,
} from '@cardstack/runtime-common';
import type { ResolvedURL } from '@cardstack/runtime-common/loader';
import type { Query } from '@cardstack/runtime-common/query';
import { importResource } from '../resources/import';

type CardAPI = typeof import('https://cardstack.com/base/card-api');

export default class CardService extends Service {
  @service declare loaderService: LoaderService;
  @service declare localRealm: LocalRealm;

  private apiModule = importResource(
    this,
    () => 'https://cardstack.com/base/card-api'
  );

  private get api() {
    if (!this.apiModule.module) {
      throw new Error(
        `bug: Card API has not loaded yet--make sure to await this.loaded before using the api`
      );
    }
    return this.apiModule.module as CardAPI;
  }

  private async fetchJSON(
    url: string,
    opts?: RequestInit
  ): Promise<LooseSingleCardDocument> {
    let response = await this.loaderService.loader.fetch(url, {
      headers: { Accept: 'application/vnd.api+json' },
      ...opts,
    });
    if (!response.ok) {
      throw new Error(
        `status: ${response.status} - ${
          response.statusText
        }. ${await response.text()}`
      );
    }
    return await response.json();
  }

  async create(json: LooseSingleCardDocument): Promise<Card> {
    await this.apiModule.loaded;
    return await this.api.createFromSerialized(json, this.localRealm.url, {
      loader: this.loaderService.loader,
    });
  }

  async load(url: string | undefined): Promise<Card | undefined> {
    if (!url) {
      return;
    }
    let json = await this.fetchJSON(url);
    if (!isSingleCardDocument(json)) {
      throw new Error(
        `bug: server returned a non card document for ${url}: ${JSON.stringify(
          json,
          null,
          2
        )}`
      );
    }
    return await this.create(json);
  }

  async save(card: Card): Promise<Card> {
    let cardJSON = this.api.serializeCard(card, { includeComputeds: true });
    let json = await this.fetchJSON(card.id ?? this.localRealm.url, {
      method: card.id ? 'PATCH' : 'POST',
      body: JSON.stringify(cardJSON, null, 2),
    });
    return await this.create(json);
  }

  async search(query: Query, realmURL: string | ResolvedURL): Promise<Card[]> {
    let json = await this.fetchJSON(`${realmURL}_search?${stringify(query)}`);
    if (!isCardCollectionDocument(json)) {
      throw new Error(
        `The realm search response was not a card collection document: ${JSON.stringify(
          json,
          null,
          2
        )}`
      );
    }
    return await Promise.all(
      json.data.map(async (doc) => await this.create({ data: doc }))
    );
  }
}
