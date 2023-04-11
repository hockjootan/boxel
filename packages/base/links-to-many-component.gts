import GlimmerComponent from '@glimmer/component';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { type Card, type Box, type Format, type Field } from './card-api';
import { getBoxComponent } from './field-component';
import type { ComponentLike } from '@glint/template';
import { CardContainer } from '@cardstack/boxel-ui';
import {
  restartableTask,
  type EncapsulatedTaskDescriptor as Descriptor,
} from 'ember-concurrency';
import {
  chooseCard,
  baseCardRef,
  identifyCard,
} from '@cardstack/runtime-common';

interface Signature {
  Args: {
    model: Box<Card>;
    arrayField: Box<Card[]>;
    format: Format;
    field: Field<typeof Card>;
    cardTypeFor(
      field: Field<typeof Card>,
      boxedElement: Box<Card>
    ): typeof Card;
  };
}

class LinksToManyEditor extends GlimmerComponent<Signature> {
  <template>
    <CardContainer
      class='contains-many-editor'
      @displayBoundaries={{true}}
      data-test-links-to-many={{this.args.field.name}}
    >
      <ul>
        {{#each @arrayField.children as |boxedElement i|}}
          <li data-test-item={{i}}>
            {{#let
              (getBoxComponent
                (this.args.cardTypeFor @field boxedElement)
                'embedded'
                boxedElement
              )
              as |Item|
            }}
              <Item />
            {{/let}}
            <button
              {{on 'click' (fn this.remove i)}}
              type='button'
              data-test-remove={{i}}
            >Remove</button>
          </li>
        {{/each}}
      </ul>
      <button {{on 'click' this.add}} type='button' data-test-add-new>+ Add New</button>
    </CardContainer>
  </template>

  add = () => {
    (this.chooseCard as unknown as Descriptor<any, any[]>).perform();
  };

  private chooseCard = restartableTask(async () => {
    let selectedCards = (this.args.model.value as any)[this.args.field.name];
    let selectedCardsQuery =
      selectedCards?.map((card: any) => ({ not: { eq: { id: card.id } } })) ??
      [];
    let type = identifyCard(this.args.field.card) ?? baseCardRef;
    let chosenCard: Card | undefined = await chooseCard(
      {
        filter: {
          every: [{ type }, ...selectedCardsQuery],
        },
      },
      { offerToCreate: type }
    );
    if (chosenCard) {
      selectedCards.push(chosenCard);
    }
  });

  remove = (index: number) => {
    (this.args.model.value as any)[this.args.field.name].splice(index, 1);
  };
}

export function getLinksToManyComponent({
  model,
  arrayField,
  format,
  field,
  cardTypeFor,
}: {
  model: Box<Card>;
  arrayField: Box<Card[]>;
  format: Format;
  field: Field<typeof Card>;
  cardTypeFor(field: Field<typeof Card>, boxedElement: Box<Card>): typeof Card;
}): ComponentLike<{ Args: {}; Blocks: {} }> {
  if (format === 'edit') {
    return class LinksToManyEditorTemplate extends GlimmerComponent {
      <template>
        <LinksToManyEditor
          @model={{model}}
          @arrayField={{arrayField}}
          @field={{field}}
          @format={{format}}
          @cardTypeFor={{cardTypeFor}}
        />
      </template>
    };
  } else {
    return class LinksToMany extends GlimmerComponent {
      <template>
        {{#each arrayField.children as |boxedElement|}}
          {{#let
            (getBoxComponent
              (cardTypeFor field boxedElement) format boxedElement
            )
            as |Item|
          }}
            <Item />
          {{/let}}
        {{/each}}
      </template>
    };
  }
}