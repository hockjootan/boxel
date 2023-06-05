import Component from '@glimmer/component';
import FreestyleUsage from 'ember-freestyle/components/freestyle/usage';
import SearchSheet, { SearchSheetMode } from './index';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { action } from '@ember/object';

const validModes = Object.values(SearchSheetMode);

export default class SearchSheetUsage extends Component {
  defaultMode: SearchSheetMode = SearchSheetMode.Closed;
  @tracked mode: SearchSheetMode = SearchSheetMode.Closed;

  @action onFocus() {
    if (this.mode == SearchSheetMode.Closed) {
      this.mode = SearchSheetMode.SearchPrompt;
    }
  }

  @action onCancel() {
    this.mode = SearchSheetMode.Closed;
  }

  <template>
    {{! template-lint-disable no-inline-styles }}
    <FreestyleUsage @name='SearchSheet'>
      <:description>
        Boxel operator mode search sheet.
      </:description>
      <:example>
        <div class='freestyle-search-sheet-example-container'>
          <SearchSheet
            @mode={{this.mode}}
            @onCancel={{this.onCancel}}
            @onFocus={{this.onFocus}}
          />
        </div>
      </:example>
      <:api as |Args|>
        <Args.String
          @name='mode'
          @description='The mode of the sheet'
          @onInput={{fn (mut this.mode)}}
          @options={{validModes}}
          @value={{this.mode}}
          @defaultValue={{this.defaultMode}}
        />
        <Args.Action
          @name='onCancel'
          @description='Action to call when the user cancels search'
        />
        <Args.Action
          @name='onFocus'
          @description='Action to call when the user focuses the search input'
        />
      </:api>
    </FreestyleUsage>
  </template>
}
