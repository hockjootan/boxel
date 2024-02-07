import {
  CardDef,
  field,
  contains,
  linksTo,
} from 'https://cardstack.com/base/card-api';
import { Currency } from './asset';
import { Component } from 'https://cardstack.com/base/card-api';
import NumberField from 'https://cardstack.com/base/number';
import StringField from 'https://cardstack.com/base/string';
import { MonetaryAmount } from './monetary-amount';

export class ExchangeRate extends CardDef {
  static displayName = 'Exchange Rate';

  @field asset1 = linksTo(Currency);
  @field asset2 = linksTo(Currency);
  @field conversionRate = contains(NumberField);
  @field title = contains(StringField, {
    computeVia(this: ExchangeRate) {
      return `${this.asset1?.symbol} → ${this.asset2?.symbol} (${this.conversionRate})`;
    },
  });

  convert(input: MonetaryAmount) {
    let result = new MonetaryAmount();
    if (input.currency === this.asset1) {
      result.currency = this.asset2;
      result.amount = input.amount * this.conversionRate;
      return result;
    } else if (input.currency === this.asset2) {
      result.currency = this.asset1;
      result.amount = input.amount * (1 / this.conversionRate);
      return result;
    } else {
      throw new Error(
        `Can only convert amounts in ${this.asset1.symbol} to ${this.asset2.symbol}, and vice versa`,
      );
    }
  }

  /*
  static isolated = class Isolated extends Component<typeof this> {
    <template></template>
  }

  static embedded = class Embedded extends Component<typeof this> {
    <template></template>
  }

  static atom = class Atom extends Component<typeof this> {
    <template></template>
  }

  static edit = class Edit extends Component<typeof this> {
    <template></template>
  }





  */
}
