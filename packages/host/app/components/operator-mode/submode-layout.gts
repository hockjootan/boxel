import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

import onClickOutside from 'ember-click-outside/modifiers/on-click-outside';

import { and, not } from '@cardstack/boxel-ui/helpers';

import AiAssistantButton from '@cardstack/host/components/ai-assistant/button';
import AiAssistantPanel from '@cardstack/host/components/ai-assistant/panel';
import ProfileAvatarIcon from '@cardstack/host/components/operator-mode/profile-avatar-icon';
import ProfileInfoPopover from '@cardstack/host/components/operator-mode/profile-info-popover';
import ProfileSettingsModal from '@cardstack/host/components/operator-mode/profile-settings-modal';
import ENV from '@cardstack/host/config/environment';
import { assertNever } from '@cardstack/host/utils/assert-never';

import type { CardDef } from 'https://cardstack.com/base/card-api';

import SearchSheet, {
  SearchSheetMode,
  SearchSheetModes,
} from '../search-sheet';
import SubmodeSwitcher, { Submode, Submodes } from '../submode-switcher';

import type MatrixService from '../../services/matrix-service';
import type OperatorModeStateService from '../../services/operator-mode-state-service';

const { APP } = ENV;

interface Signature {
  Element: HTMLDivElement;
  Args: {
    hideAiAssistant?: boolean;
    onSearchSheetOpened?: () => void;
    onSearchSheetClosed?: () => void;
    onCardSelectFromSearch: (card: CardDef) => void;
  };
  Blocks: {
    default: [openSearch: () => void];
  };
}

export default class SubmodeLayout extends Component<Signature> {
  @tracked private isAiAssistantVisible = false;
  @tracked private searchSheetMode: SearchSheetMode = SearchSheetModes.Closed;
  @tracked private profileSettingsOpened = false;
  @tracked private profileSummaryOpened = false;
  @service private declare operatorModeStateService: OperatorModeStateService;
  @service declare matrixService: MatrixService;

  private get aiAssistantVisibilityClass() {
    return this.isAiAssistantVisible
      ? 'ai-assistant-open'
      : 'ai-assistant-closed';
  }

  private get allStackItems() {
    return this.operatorModeStateService.state?.stacks.flat() ?? [];
  }

  private get lastCardInRightMostStack(): CardDef | null {
    if (this.allStackItems.length <= 0) {
      return null;
    }

    return this.allStackItems[this.allStackItems.length - 1].card;
  }

  @action private updateSubmode(submode: Submode) {
    switch (submode) {
      case Submodes.Interact:
        this.operatorModeStateService.updateCodePath(null);
        break;
      case Submodes.Code:
        this.operatorModeStateService.updateCodePath(
          this.lastCardInRightMostStack
            ? new URL(this.lastCardInRightMostStack.id + '.json')
            : null,
        );
        break;
      default:
        throw assertNever(submode);
    }

    this.operatorModeStateService.updateSubmode(submode);
  }

  @action
  private toggleChat() {
    this.isAiAssistantVisible = !this.isAiAssistantVisible;
  }

  @action private closeSearchSheet() {
    this.searchSheetMode = SearchSheetModes.Closed;
    this.args.onSearchSheetClosed?.();
  }

  @action private expandSearchToShowResults(_term: string) {
    this.searchSheetMode = SearchSheetModes.SearchResults;
  }

  @action private openSearchSheetToPrompt() {
    if (this.searchSheetMode == SearchSheetModes.Closed) {
      this.searchSheetMode = SearchSheetModes.SearchPrompt;
    }

    this.args.onSearchSheetOpened?.();
  }

  @action private handleCardSelectFromSearch(card: CardDef) {
    this.args.onCardSelectFromSearch(card);
    this.closeSearchSheet();
  }

  @action toggleProfileSettings() {
    this.profileSettingsOpened = !this.profileSettingsOpened;

    this.profileSummaryOpened = false;
  }

  @action toggleProfileSummary() {
    this.profileSummaryOpened = !this.profileSummaryOpened;
  }

  <template>
    <div
      class='operator-mode-with-ai-assistant
        {{this.aiAssistantVisibilityClass}}'
    >
      <SubmodeSwitcher
        @submode={{this.operatorModeStateService.state.submode}}
        @onSubmodeSelect={{this.updateSubmode}}
        class='submode-switcher'
      />
      {{yield this.openSearchSheetToPrompt}}

      {{#if (and APP.experimentalAIEnabled (not @hideAiAssistant))}}
        {{#if this.isAiAssistantVisible}}
          <AiAssistantPanel
            @onClose={{this.toggleChat}}
            class='ai-assistant-panel'
          />
        {{else}}
          <AiAssistantButton class='chat-btn' {{on 'click' this.toggleChat}} />
        {{/if}}
      {{/if}}
    </div>

    <div class='profile-icon-container'>
      <button
        class='profile-icon-button'
        {{on 'click' this.toggleProfileSummary}}
        data-test-profile-icon-button
      >
        <ProfileAvatarIcon @userId={{this.matrixService.userId}} />
      </button>
    </div>

    {{#if this.profileSummaryOpened}}
      <ProfileInfoPopover
        {{onClickOutside
          this.toggleProfileSummary
          exceptSelector='.profile-icon-button'
        }}
        @toggleProfileSettings={{this.toggleProfileSettings}}
      />
    {{/if}}

    {{#if this.profileSettingsOpened}}
      <ProfileSettingsModal
        @toggleProfileSettings={{this.toggleProfileSettings}}
      />
    {{/if}}

    <SearchSheet
      @mode={{this.searchSheetMode}}
      @onBlur={{this.closeSearchSheet}}
      @onCancel={{this.closeSearchSheet}}
      @onFocus={{this.openSearchSheetToPrompt}}
      @onSearch={{this.expandSearchToShowResults}}
      @onCardSelect={{this.handleCardSelectFromSearch}}
    />

    <style>
      .operator-mode-with-ai-assistant {
        display: flex;
        height: 100%;
      }

      .operator-mode-with-ai-assistant > * {
        z-index: 1;
      }

      .ai-assistant-open {
        grid-template-columns: 1.5fr 0.5fr;
      }

      .chat-btn {
        position: absolute;
        bottom: var(--boxel-sp);
        right: var(--boxel-sp);
        margin-right: 0;
        background-color: var(--boxel-ai-purple);
        box-shadow: var(--boxel-deep-box-shadow);
      }

      .ai-assistant-panel {
        flex: 0;
        flex-basis: 371px;
        height: 100%;
      }

      .submode-switcher {
        position: absolute;
        top: 0;
        left: 0;
        padding: var(--boxel-sp);
      }

      .profile-icon-container {
        bottom: 0;
        position: absolute;
        width: var(--search-sheet-closed-height);
        height: var(--search-sheet-closed-height);
        border-radius: 50px;
        margin-left: var(--boxel-sp);
        z-index: 1;
      }

      .profile-icon-button {
        border: 0;
        padding: 0;
        background: transparent;
      }
    </style>
  </template>
}
